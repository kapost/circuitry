require 'spec_helper'

RSpec.describe Concord::Subscriber, type: :model do
  subject { described_class.new(queue, options) }

  let(:queue) { 'https://sqs.amazon.com/account/queue' }
  let(:options) { {} }

  describe '#subscribe' do
    describe 'when queue is not set' do
      let(:queue) { nil }

      it 'raises an error' do
        expect { subject.subscribe(queue) }.to raise_error(ArgumentError)
      end
    end

    describe 'when queue is set' do
      let(:queue) { 'https://sqs.amazon.com/account/queue' }
      let(:block) { ->(_) { } }
      let(:mock_sqs) { double('SQS', receive_message: double('Response', body: { 'Message' => messages })) }
      let(:messages) { [] }

      before do
        allow(subject).to receive(:sqs).and_return(mock_sqs)
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
          expect(logger).to have_received(:warn).with('Concord unable to subscribe: AWS configuration is not set.')
        end
      end
    end
  end
end
