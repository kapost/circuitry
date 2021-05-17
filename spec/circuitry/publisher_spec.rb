require 'spec_helper'

RSpec.describe Circuitry::Publisher, type: :model do
  subject { described_class.new(options) }

  let(:options) { {} }

  it { is_expected.to be_a Circuitry::Concerns::Async }

  describe '#publish' do
    describe 'when topic name is not set' do
      let(:topic_name) { nil }
      let(:object) { double('Object') }

      it 'raises an error' do
        expect { subject.publish(topic_name, object) }.to raise_error(ArgumentError)
      end
    end

    describe 'when object is not set' do
      let(:topic_name) { 'topic' }
      let(:object) { nil }

      it 'raises an error' do
        expect { subject.publish(topic_name, object) }.to raise_error(ArgumentError)
      end
    end

    describe 'when topic name and object are set' do
      let(:topic_name) { 'topic' }
      let(:object) { double('Object', to_json: '{"foo":"bar"}') }
      let(:topic) { double('Topic', arn: 'arn:aws:sns:us-east-1:123456789012:some-topic-name') }
      let(:logger) { double('Logger', debug: nil, info: nil, warn: nil, error: nil) }
      let(:mock_sns) { double('SNS', publish: true) }

      before do
        allow(Circuitry.publisher_config).to receive(:logger).and_return(logger)
        allow(Circuitry::Topic).to receive(:find).with(topic_name).and_return(topic)
        allow(subject).to receive(:sns).and_return(mock_sns)
      end

      describe 'when AWS credentials are set' do
        before do
          allow(Circuitry.publisher_config).to receive(:aws_options).and_return(access_key_id: 'key', secret_access_key: 'secret', region: 'region')
          allow(logger).to receive(:debug)
        end

        shared_examples_for 'a valid publish request' do
          it 'publishes to SNS' do
            subject.publish(topic_name, object)
            expect(mock_sns).to have_received(:publish).with(topic_arn: topic.arn, message: object.to_json)
          end

          describe 'when a connection error occurs' do
            let(:error) { Seahorse::Client::NetworkingError.new(StandardError.new('test error')) }

            describe 'on the first try' do
              before do
                attempts = 0

                allow(mock_sns).to receive(:publish) do
                  attempts += 1
                  raise error if attempts == 1
                end
              end

              it 'logs a warning' do
                subject.publish(topic_name, object)
                expect(logger).to have_received(:warn).with("Error publishing attempt #1: #{error.class} (test error); retrying...")
              end

              it 'retries' do
                subject.publish(topic_name, object)
                expect(mock_sns).to have_received(:publish).with(topic_arn: topic.arn, message: object.to_json).twice
              end

              it 'does not raise the error' do
                expect { subject.publish(topic_name, object) }.to_not raise_error
              end
            end

            describe 'repeatedly' do
              before do
                allow(mock_sns).to receive(:publish).and_raise(error)
              end

              it 'logs 2 warnings' do
                subject.publish(topic_name, object) rescue nil
                expect(logger).to have_received(:warn).with("Error publishing attempt #1: #{error.class} (test error); retrying...")
                expect(logger).to have_received(:warn).with("Error publishing attempt #2: #{error.class} (test error); retrying...")
              end

              it 'gives up after 3 tries' do
                subject.publish(topic_name, object) rescue nil
                expect(mock_sns).to have_received(:publish).with(topic_arn: topic.arn, message: object.to_json).thrice
              end

              it 'raises the error' do
                expect { subject.publish(topic_name, object) }.to raise_error(error.class)
              end
            end
          end

          describe 'when the message is invalid' do
            before do
              mock_error = Aws::SNS::Errors::InvalidParameter.new({}, "Invalid parameter: Message too long")
              allow(mock_sns).to receive(:publish).and_raise(mock_error)
            end

            it 'raises the error' do
              expect { subject.publish(topic_name, object) }.to raise_error do |ex|
                expect(ex).to be_a(Circuitry::SnsPublishError)
                error_message = JSON.parse(ex.message)
                message = JSON.parse(error_message["message"])

                expect(error_message["error"]).to eq("Aws::SNS::Errors::InvalidParameter: Invalid parameter: Message too long")
                expect(error_message["topic_arn"]).to eq("arn:aws:sns:us-east-1:123456789012:some-topic-name")
                expect(message).to eq("foo" => "bar")
              end
            end
          end
        end

        describe 'synchonously' do
          let(:options) { { async: false } }

          it 'does not process asynchronously' do
            expect(subject).to_not receive(:process_asynchronously)
            subject.publish(topic_name, object)
          end

          it_behaves_like 'a valid publish request'
        end

        describe 'asynchronously' do
          before do
            allow(subject).to receive(:process_asynchronously) { |&block| block.call }
          end

          let(:options) { { async: true } }

          it 'processes asynchronously' do
            subject.publish(topic_name, object)
            expect(subject).to have_received(:process_asynchronously)
          end

          it_behaves_like 'a valid publish request'
        end
      end

      describe 'when AWS credentials are not set' do
        before do
          allow(Circuitry.publisher_config).to receive(:aws_options).and_return(access_key_id: '', secret_access_key: '', region: 'region')
        end

        it 'does not publish to SNS' do
          subject.publish(topic_name, object) rescue nil
          expect(mock_sns).to_not have_received(:publish).with(topic_arn: topic.arn, message: object.to_json)
        end

        it 'logs a warning' do
          expect { subject.publish(topic_name, object) }.to raise_error(Circuitry::PublishError)
        end
      end
    end
  end
end
