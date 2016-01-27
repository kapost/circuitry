require 'spec_helper'

RSpec.describe Circuitry::QueueCreator, type: :model do
  describe '.find_or_create' do
    subject { described_class }
    before do
      allow_any_instance_of(subject).to receive(:sqs).and_return(mock_sqs)
    end

    let(:queue_url) { 'http://sqs.amazontest.com/howdy' }
    let(:queue_arn) { 'amazon:test:howdy' }
    let(:queue_attributes) { OpenStruct.new(attributes: { 'QueueArn' => queue_arn }) }
    let(:create_queue_response) { OpenStruct.new(queue_url: queue_url) }
    let(:mock_sqs) { double('SQS', create_queue: create_queue_response, set_queue_attributes: true, get_queue_attributes: queue_attributes) }

    it 'creates and returns primary queue' do
      queue = subject.find_or_create('howdy')
      expect(queue.name).to eql('howdy')
    end

    context 'when dead letter queue name option is given' do
      it 'creates dead letter' do
        subject.find_or_create('howdy', dead_letter_queue_name: 'howdy-failures')
        expect(mock_sqs).to have_received(:create_queue).with(hash_including(queue_name: 'howdy-failures'))
      end

      it 'sets redrive policy on primary queue' do
        subject.find_or_create('howdy', dead_letter_queue_name: 'howdy-failures')
        expect(mock_sqs).to have_received(:set_queue_attributes).with(hash_including(queue_url: queue_url, attributes: { 'RedrivePolicy' => "{\"maxReceiveCount\":\"8\", \"deadLetterTargetArn\":\"#{queue_arn}\"}"}))
      end
    end

    it 'creates queue with visibility timeout' do
      subject.find_or_create('howdy')
      expect(mock_sqs).to have_received(:create_queue).with(hash_including(queue_name: 'howdy', attributes: { 'VisibilityTimeout' => '1800' }))
    end
  end
end
