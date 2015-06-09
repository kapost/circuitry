require 'spec_helper'

RSpec.describe Concord::Publisher, type: :model do
  subject { described_class.new(options) }

  let(:options) { {} }

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
      let(:mock_sns) { double('SNS', publish: true) }

      before do
        allow(Concord::TopicCreator).to receive(:find_or_create).with(topic_name).and_return(topic)
        allow(subject).to receive(:sns).and_return(mock_sns)
      end

      describe 'when AWS credentials are set' do
        before do
          allow(subject).to receive(:can_publish?).and_return(true)
        end

        describe 'asynchronously' do
          before do
            allow(subject).to receive(:fork) { |&block| block.call }.and_return(pid)
            allow(Process).to receive(:detach)
          end

          let(:options) { { async: true } }
          let(:pid) { 'pid' }

          it 'forks a detached process' do
            subject.publish(topic_name, object)
            expect(subject).to have_received(:fork)
            expect(Process).to have_received(:detach).with(pid)
          end

          it 'publishes to SNS' do
            subject.publish(topic_name, object)
            expect(mock_sns).to have_received(:publish).with(topic.arn, object.to_json)
          end
        end

        describe 'synchonously' do
          it 'publishes to SNS' do
            subject.publish(topic_name, object)
            expect(mock_sns).to have_received(:publish).with(topic.arn, object.to_json)
          end
        end
      end

      describe 'when AWS credentials are not set' do
        before do
          allow(subject).to receive(:can_publish?).and_return(false)
          allow(subject).to receive(:logger).and_return(logger)
        end

        let(:logger) { double('Logger', warn: true) }

        it 'does not publish to SNS' do
          subject.publish(topic_name, object)
          expect(mock_sns).to_not have_received(:publish).with(topic.arn, object.to_json)
        end

        it 'logs a warning' do
          subject.publish(topic_name, object)
          expect(logger).to have_received(:warn).with('Concord unable to publish: AWS configuration is not set.')
        end
      end
    end
  end
end
