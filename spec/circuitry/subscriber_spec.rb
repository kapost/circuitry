require 'spec_helper'

RSpec.describe Circuitry::Subscriber, type: :model do
  subject { described_class.new(queue, options) }

  let(:queue) { 'https://sqs.amazon.com/account/queue' }
  let(:options) { {} }

  it { is_expected.to be_a Circuitry::Concerns::Async }

  describe '#subscribe' do
    before do
      Circuitry::Locks::Memory.store.clear
    end

    describe 'when queue is not set' do
      let(:queue) { nil }
      let(:block) { ->{ } }

      it 'raises an error' do
        expect { subject.subscribe(queue, &block) }.to raise_error(ArgumentError)
      end
    end

    describe 'when block is not given' do
      let(:queue) { 'https://sqs.amazon.com/account/queue' }

      it 'raises an error' do
        expect { subject.subscribe(queue) }.to raise_error(ArgumentError)
      end
    end

    describe 'when queue and block are set' do
      let(:queue) { 'https://sqs.amazon.com/account/queue' }
      let(:block) { ->(_, _) { } }
      let(:mock_sqs) { double('SQS', receive_message: double('Response', body: { 'Message' => messages })) }
      let(:mock_logger) { double('Logger', info: nil, warn: nil, error: nil) }
      let(:messages) { [] }

      before do
        allow(subject).to receive(:sqs).and_return(mock_sqs)
        allow(subject).to receive(:logger).and_return(mock_logger)
        allow(subject).to receive(:loop) do |&block|
          block.call
        end
      end

      describe 'when AWS credentials are set' do
        before do
          allow(subject).to receive(:can_subscribe?).and_return(true)
        end

        it 'subscribes to SQS' do
          subject.subscribe(&block)
          expect(mock_sqs).to have_received(:receive_message).with(queue, any_args)
        end

        describe 'when a connection error is raised' do
          it 'raises wraps the error' do
            allow(subject).to receive(:receive_messages).and_raise(described_class::CONNECTION_ERRORS.first, 'Forbidden')
            expect { subject.subscribe(&block) }.to raise_error(Circuitry::SubscribeError)
          end
        end

        shared_examples_for 'a valid subscribe request' do
          let(:messages) do
            [
                { 'MessageId' => 'one', 'ReceiptHandle' => 'delete-one', 'Body' => { 'Message' => 'Foo'.to_json, 'TopicArn' => 'arn:aws:sns:us-east-1:123456789012:test-event-task-changed' }.to_json },
                { 'MessageId' => 'two', 'ReceiptHandle' => 'delete-two', 'Body' => { 'Message' => 'Bar'.to_json, 'TopicArn' => 'arn:aws:sns:us-east-1:123456789012:test-event-comment' }.to_json },
            ]
          end

          before do
            allow(mock_sqs).to receive(:delete_message)
          end

          it 'processes each message' do
            expect(block).to receive(:call).with('Foo', 'test-event-task-changed')
            expect(block).to receive(:call).with('Bar', 'test-event-comment')
            subject.subscribe(&block)
          end

          it 'deletes each message' do
            subject.subscribe(&block)
            expect(mock_sqs).to have_received(:delete_message).with(queue, 'delete-one')
            expect(mock_sqs).to have_received(:delete_message).with(queue, 'delete-two')
          end

          describe 'when a duplicate message is received' do
            let(:messages) do
              2.times.map do
                { 'MessageId' => 'one', 'ReceiptHandle' => 'delete-one', 'Body' => { 'Message' => 'Foo'.to_json, 'TopicArn' => 'arn:aws:sns:us-east-1:123456789012:test-event-task-changed' }.to_json }
              end
            end

            describe 'when locking is disabled' do
              let(:options) { { async: async, lock: false } }

              it 'processes the duplicate' do
                expect(block).to receive(:call).with('Foo', 'test-event-task-changed').twice
                subject.subscribe(&block)
              end

              it 'deletes each message' do
                subject.subscribe(&block)
                expect(mock_sqs).to have_received(:delete_message).with(queue, 'delete-one').twice
              end
            end

            describe 'when locking is enabled' do
              let(:options) { { async: async, lock: true } }

              it 'does not process the duplicate' do
                expect(block).to receive(:call).with('Foo', 'test-event-task-changed').once
                subject.subscribe(&block)
              end

              it 'deletes each message' do
                subject.subscribe(&block)
                expect(mock_sqs).to have_received(:delete_message).with(queue, 'delete-one').twice
              end
            end
          end

          describe 'when processing fails' do
            let(:block) { ->(message, topic) { raise error if message == 'Foo' } }
            let(:error) { StandardError.new('test error') }

            it 'does not raise the error' do
              expect { subject.subscribe(&block) }.to_not raise_error
            end

            it 'logs error for failing messages' do
              subject.subscribe(&block)
              expect(mock_logger).to have_received(:error).with('Error handling message one: test error')
            end

            it 'does not log error for successful messages' do
              subject.subscribe(&block)
              expect(mock_logger).to_not have_received(:error).with('Error handling message two: test error')
            end

            it 'deletes successful messages' do
              subject.subscribe(&block)
              expect(mock_sqs).to have_received(:delete_message).with(queue, 'delete-two')
            end

            it 'does not delete failing messages' do
              subject.subscribe(&block)
              expect(mock_sqs).to_not have_received(:delete_message).with(queue, 'delete-one')
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
            allow(mock_sqs).to receive(:delete_message)
          end

          let(:async) { true }
          let(:options) { { async: async } }
          let(:messages) do
            [
                { 'MessageId' => 'one', 'ReceiptHandle' => 'delete-one', 'Body' => { 'Message' => 'Foo'.to_json, 'TopicArn' => 'arn:aws:sns:us-east-1:123456789012:test-event-task-changed' }.to_json },
                { 'MessageId' => 'two', 'ReceiptHandle' => 'delete-two', 'Body' => { 'Message' => 'Bar'.to_json, 'TopicArn' => 'arn:aws:sns:us-east-1:123456789012:test-event-comment' }.to_json },
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
          allow(subject).to receive(:can_subscribe?).and_return(false)
          allow(subject).to receive(:logger).and_return(logger)
        end

        let(:logger) { double('Logger', warn: true) }

        it 'does not subscribe to SNS' do
          subject.subscribe(&block)
          expect(mock_sqs).to_not have_received(:receive_message).with(queue, any_args)
        end

        it 'logs a warning' do
          subject.subscribe(&block)
          expect(logger).to have_received(:warn).with('Circuitry unable to subscribe: AWS configuration is not set.')
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
