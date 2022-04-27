require 'spec_helper'

RSpec.describe Circuitry::Subscriber, type: :model do
  subject { described_class.new(options) }

  let(:queue) { 'https://sqs.amazon.com/account/queue' }
  let(:options) { {} }

  it { is_expected.to be_a Circuitry::Concerns::Async }

  before do
    allow(Circuitry::Queue).to receive(:find).and_return(double('Queue', url: queue))
  end

  describe '.new' do
    subject { described_class }

    describe 'when lock' do
      subject { described_class }

      let(:options) { { lock: lock } }

      shared_examples_for 'a valid lock strategy' do |lock_class|
        it 'does not raise an error' do
          expect { subject.new(options) }.to_not raise_error
        end

        it 'sets the lock strategy' do
          subscriber = subject.new(options)
          expect(subscriber.lock).to be_a lock_class
        end
      end

      describe 'is true' do
        let(:lock) { true }
        it_behaves_like 'a valid lock strategy', Circuitry::Locks::Memory
      end

      describe 'is false' do
        let(:lock) { false }
        it_behaves_like 'a valid lock strategy', Circuitry::Locks::NOOP
      end

      describe 'is a specific strategy' do
        let(:lock) { Circuitry::Locks::Redis.new(client: MockRedis.new) }
        it_behaves_like 'a valid lock strategy', Circuitry::Locks::Redis
      end

      describe 'is invalid' do
        let(:lock) { 'invalid' }

        it 'raises an error' do
          expect { subject.new(options) }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe '#subscribe' do
    before do
      Circuitry::Locks::Memory.store.clear
    end

    describe 'when a block is not given' do
      it 'raises an error' do
        expect { subject.subscribe(queue) }.to raise_error(ArgumentError)
      end
    end

    describe 'when a block is given' do
      let(:block) { ->(_, _) { } }
      let(:logger) { double('Logger', debug: nil, info: nil, warn: nil, error: nil) }
      let(:batch_delete_response) { double('Aws::SQS::Types::DeleteMessageBatchResult', successful: ['item'], failed: []) }
      let(:mock_sqs) { double('Aws::SQS::Client', delete_message: true, delete_message_batch: batch_delete_response) }
      let(:mock_poller) { double('Aws::SQS::QueuePoller', before_request: true) }
      let(:messages) { [] }

      before do
        allow(Circuitry.subscriber_config).to receive(:logger).and_return(logger)
        allow(logger).to receive(:debug)
        allow(subject).to receive(:sqs).and_return(mock_sqs)
        allow(Aws::SQS::QueuePoller).to receive(:new).with(queue, client: mock_sqs).and_return(mock_poller)

        allow(mock_poller).to receive(:poll) do |&block|
          block.call(messages)
        end
      end

      describe 'when AWS credentials are set' do
        before do
          allow(Circuitry.subscriber_config).to receive(:aws_options).and_return(access_key_id: 'key', secret_access_key: 'secret', region: 'region')
        end

        it 'subscribes to SQS' do
          subject.subscribe(&block)
          expect(mock_poller).to have_received(:poll)
        end

        describe 'when a connection error is raised' do
          before do
            allow(subject).to receive(:process_messages).and_raise(error)
          end

          let(:error) { described_class::CONNECTION_ERRORS.first.new(double('Seahorse::Client::RequestContext'), 'Queue does not exist') }

          it 'raises a wrapped error' do
            expect { subject.subscribe(&block) }.to raise_error(Circuitry::SubscribeError)
          end

          it 'logs an error' do
            subject.subscribe(&block) rescue nil
            expect(logger).to have_received(:error)
          end
        end

        shared_examples_for 'a valid subscribe request' do
          context 'when the batch_size is 1 and messages is not an Array' do
            let(:messages) do
              double('Aws::SQS::Types::Message', message_id: 'one', receipt_handle: 'delete-one', body: { 'Message' => 'Foo'.to_json, 'TopicArn' => 'arn:aws:sns:us-east-1:123456789012:test-event-task-changed' }.to_json)
            end
            let(:options) { { batch_size: 1 } }

            it 'processes the message' do
              expect(block).to receive(:call).with('Foo', 'test-event-task-changed')
              subject.subscribe(&block)
            end

            it 'deletes the message' do
              subject.subscribe(&block)
              expect(mock_sqs).to have_received(:delete_message).with(queue_url: queue, receipt_handle: 'delete-one')
            end

            describe 'when disabling auto_delete' do
              let(:options) { { auto_delete: false } }
              let(:messages) do
                double('Aws::SQS::Types::Message', message_id: 'one', receipt_handle: 'delete-one', body: { 'Message' => 'Foo'.to_json, 'TopicArn' => 'arn:aws:sns:us-east-1:123456789012:test-event-task-changed' }.to_json)
              end
              let(:block) {
                ->(_, _, message_entry) do
                  expect(@message_entry).to be_nil
                  @message_entry = message_entry
                end
              }

              before do
                @message_entry = nil
              end

              it 'does not delete the messages' do
                subject.subscribe(&block)
                expect(mock_sqs).to_not have_received(:delete_message).with(queue_url: queue, receipt_handle: 'delete-one')
              end

              it 'passes the message_entry to the subscriber block' do
                subject.subscribe(&block)
                expect(@message_entry[:id]).to eq 'one'
                expect(@message_entry[:receipt_handle]).to eq 'delete-one'
              end
            end

            context 'when filtering strategy is provided' do
              let(:filter_with) { ->(messages) { messages.reject { |message| message.body == 'Foo' } } }
              let(:options) { { filter_with: filter_with } }

              it 'removes messages that do not match the strategy' do
                expect(block).not_to receive(:call).with('Foo', 'test-event-task-changed')
                subject.subscribe(&block)
              end

              it 'removes messages that were filtered out' do
                entries = [{ id: messages.message_id, receipt_handle: messages.receipt_handle }]
                subject.subscribe(&block)
                expect(mock_sqs).to have_received(:delete_message_batch).with(queue_url: queue, entries: entries)
              end
            end
          end

          context 'when the batch_size is greater than 1' do
            let(:messages) do
              [
                double('Aws::SQS::Types::Message', message_id: 'one', receipt_handle: 'delete-one', body: { 'Message' => 'Foo'.to_json, 'TopicArn' => 'arn:aws:sns:us-east-1:123456789012:test-event-task-changed' }.to_json),
                double('Aws::SQS::Types::Message', message_id: 'two', receipt_handle: 'delete-two', body: { 'Message' => 'Bar'.to_json, 'TopicArn' => 'arn:aws:sns:us-east-1:123456789012:test-event-comment' }.to_json),
              ]
            end

            it 'processes each message' do
              expect(block).to receive(:call).with('Foo', 'test-event-task-changed')
              expect(block).to receive(:call).with('Bar', 'test-event-comment')
              subject.subscribe(&block)
            end

            it 'deletes each message' do
              subject.subscribe(&block)
              expect(mock_sqs).to have_received(:delete_message).with(queue_url: queue, receipt_handle: 'delete-one')
              expect(mock_sqs).to have_received(:delete_message).with(queue_url: queue, receipt_handle: 'delete-two')
            end

            it 'does not delete batch messages' do
              subject.subscribe(&block)
              expect(mock_sqs).not_to have_received(:delete_message_batch)
            end

            context 'when filtering strategy is provided' do
              let(:filter_with) { ->(messages) { messages.reject { |message| message.body == 'Bar' } } }
              let(:options) { { filter_with: filter_with } }

              it 'removes messages that do not match the strategy' do
                expect(block).to receive(:call).with('Foo', 'test-event-task-changed')
                expect(block).not_to receive(:call).with('Bar', 'test-event-comment')
                subject.subscribe(&block)
              end

              it 'removes messages that were filtered out' do
                entries = [{ id: messages[1].message_id, receipt_handle: messages[1].receipt_handle }]
                subject.subscribe(&block)
                expect(mock_sqs).to have_received(:delete_message_batch).with(queue_url: queue, entries: entries)
              end

              context 'when message being batch deleted was not deleted successfully' do
                let(:failure) { double('Aws::SQS::Types::BatchResultErrorEntry', id: messages[1].message_id, message: 'Not deleted' ) }
                let(:batch_delete_response) { double('Aws::SQS::Types::DeleteMessageBatchResult', successful: [], failed: [failure]) }

                it 'logs errors for failed messages' do
                  subject.subscribe(&block)
                  expect(mock_sqs).to have_received(:delete_message_batch)
                  expect(logger).to have_received(:error).twice
                end
              end
            end

            context 'when a duplicate message is received' do
              let(:options) { { async: async, lock: lock } }
              let(:messages) do
                2.times.map do
                  double('Aws::SQS::Types::Message', message_id: 'one', receipt_handle: 'delete-one', body: { 'Message' => 'Foo'.to_json, 'TopicArn' => 'arn:aws:sns:us-east-1:123456789012:test-event-task-changed' }.to_json)
                end
              end

              context 'when locking is disabled' do
                let(:lock) { false }

                it 'processes the duplicate' do
                  expect(block).to receive(:call).with('Foo', 'test-event-task-changed').twice
                  subject.subscribe(&block)
                end

                it 'deletes each message' do
                  subject.subscribe(&block)
                  expect(mock_sqs).to have_received(:delete_message).with(queue_url: queue, receipt_handle: 'delete-one').twice
                end
              end

              context 'when locking is enabled' do
                let(:lock) { true }

                it 'does not process the duplicate' do
                  expect(block).to receive(:call).with('Foo', 'test-event-task-changed').once
                  subject.subscribe(&block)
                end

                it 'deletes each message' do
                  subject.subscribe(&block)
                  expect(mock_sqs).to have_received(:delete_message).with(queue_url: queue, receipt_handle: 'delete-one').once
                end
              end
            end

            context 'when processing fails' do
              let(:block) { ->(message, topic) { raise error if message == 'Foo' } }
              let(:error) { StandardError.new('test error') }

              describe 'when ignore_visibility_timeout is set to true' do
                let(:logger) { double('Logger', debug: nil, info: nil, warn: nil, error: nil) }
                let(:batch_delete_response) { double('Aws::SQS::Types::DeleteMessageBatchResult', successful: ['item'], failed: []) }
                let(:mock_sqs) { double('Aws::SQS::Client', delete_message: true, change_message_visibility: true, delete_message_batch: batch_delete_response) }
                let(:mock_poller) { double('Aws::SQS::QueuePoller', before_request: true) }
                let(:options) { { ignore_visibility_timeout: true } }
                let(:subject) { described_class.new(options) }

                before do
                  allow(Circuitry.subscriber_config).to receive(:logger).and_return(logger)
                  allow(subject).to receive(:sqs).and_return(mock_sqs)
                  allow(Aws::SQS::QueuePoller).to receive(:new).with(queue, client: mock_sqs).and_return(mock_poller)

                  allow(mock_poller).to receive(:poll) do |&block|
                    block.call(messages)
                  end
                end

                it 'changes the messages visibility to zero' do
                  subject.subscribe(&block)
                  expect(mock_sqs).to have_received(:change_message_visibility).with(queue_url: queue, receipt_handle: 'delete-one', visibility_timeout: 0)
                end
              end

              it 'does not raise the error' do
                expect { subject.subscribe(&block) }.to_not raise_error
              end

              it 'logs error for failing messages' do
                subject.subscribe(&block)
                expect(logger).to have_received(:error).with('Error handling message one: test error')
              end

              it 'does not log error for successful messages' do
                subject.subscribe(&block)
                expect(logger).to_not have_received(:error).with('Error handling message two: test error')
              end

              it 'deletes successful messages' do
                subject.subscribe(&block)
                expect(mock_sqs).to have_received(:delete_message).with(queue_url: queue, receipt_handle: 'delete-two')
              end

              it 'does not delete failing messages' do
                subject.subscribe(&block)
                expect(mock_sqs).to_not have_received(:delete_message).with(queue_url: queue, receipt_handle: 'delete-one')
              end

              it 'unlocks failing messages' do
                expect(subject.lock).to receive(:unlock).with('one')
                subject.subscribe(&block)
              end

              describe 'when error logger is configured' do
                let(:error_handler) { ->(_) { } }

                before do
                  allow(subject).to receive(:error_handler).and_return(error_handler)
                end

                it 'calls error handler' do
                  expect(error_handler).to receive(:call).with(error)
                  subject.subscribe(&block)
                end
              end
            end
          end

          context 'with no TopicArn (the message was not from a SNS<->SQS subscription, it was from SQS directly)' do
            let(:messages) do
              double('Aws::SQS::Types::Message', message_id: 'one', receipt_handle: 'delete-one', body: { 'Message' => 'Foo'.to_json }.to_json)
            end

            it 'processes the message' do
              expect(block).to receive(:call).with('Foo', nil)
              subject.subscribe(&block)
            end
          end

          describe 'before_message' do
            let(:messages) {
              double('Aws::SQS::Types::Message', message_id: 'one', receipt_handle: 'delete-one', body: { 'Message' => 'Foo'.to_json, 'TopicArn' => 'arn:aws:sns:us-east-1:123456789012:test-event-task-changed' }.to_json)
            }
            let(:options) { { before_message: before_message } }

            let(:before_message) do
              lambda do |_message|
                expect(@expected_messages).to eq([])
                @expected_messages << 'before_message was called'
              end
            end

            let(:block) do
              ->(_, _) do
                expect(@expected_messages).to eq(['before_message was called'])
                @expected_messages << 'subscribe block was called'
              end
            end

            before do
              @expected_messages = []
            end

            it 'calls the before_message handler before processing the messages' do
              subject.subscribe(&block)
              expect(@expected_messages).to eq(['before_message was called', 'subscribe block was called'])
            end
          end
        end

        describe 'synchronously' do
          let(:async) { false }
          let(:options) { { async: async } }

          it 'does not process asynchronously' do
            expect(subject).to_not receive(:process_asynchronously)
            subject.subscribe(&block)
          end

          it_behaves_like 'a valid subscribe request'
        end

        describe 'asynchronously' do
          before do
            allow(subject).to receive(:process_asynchronously) { |&block| block.call }
          end

          let(:async) { true }
          let(:options) { { async: async } }
          let(:messages) do
            [
              double('Aws::SQS::Types::Message', message_id: 'one', receipt_handle: 'delete-one', body: { 'Message' => 'Foo'.to_json, 'TopicArn' => 'arn:aws:sns:us-east-1:123456789012:test-event-task-changed' }.to_json),
              double('Aws::SQS::Types::Message', message_id: 'two', receipt_handle: 'delete-two', body: { 'Message' => 'Bar'.to_json, 'TopicArn' => 'arn:aws:sns:us-east-1:123456789012:test-event-comment' }.to_json),
            ]
          end

          it 'processes asynchronously' do
            subject.subscribe(&block)
            expect(subject).to have_received(:process_asynchronously).twice
          end

          it_behaves_like 'a valid subscribe request'
        end
      end

      describe 'when AWS credentials are not set' do
        before do
          allow(Circuitry.subscriber_config).to receive(:aws_options).and_return(access_key_id: '', secret_access_key: '', region: 'region')
        end

        it 'does not subscribe to SNS' do
          subject.subscribe(&block) rescue nil
          expect(mock_poller).to_not have_received(:poll)
        end

        it 'raises an error' do
          expect { subject.subscribe(&block) }.to raise_error(Circuitry::SubscribeError)
        end
      end
    end
  end

  describe '#queue' do
    it 'returns the initializer value' do
      expect(subject.queue).to eq queue
    end
  end

  describe '#wait_time' do
    let(:options) { { wait_time: 123 } }

    it 'returns the initializer value' do
      expect(subject.wait_time).to eq 123
    end
  end

  describe '#batch_size' do
    let(:options) { { batch_size: 321 } }

    it 'returns the initializer value' do
      expect(subject.batch_size).to eq 321
    end
  end
end
