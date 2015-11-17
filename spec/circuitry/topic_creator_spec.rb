require 'spec_helper'

RSpec.describe Circuitry::TopicCreator, type: :model do
  describe '.find_or_create' do
    subject { described_class }

    let(:topic_name) { 'topic' }
    let(:topic) { double('Topic') }
    let(:instance) { double('TopicCreator', topic: topic) }

    before do
      allow(subject).to receive(:new).with(topic_name).and_return(instance)
    end

    it 'delegates to a new instance' do
      subject.find_or_create(topic_name)
      expect(instance).to have_received(:topic)
    end

    it 'returns a topic' do
      expect(subject.find_or_create(topic_name)).to eq topic
    end
  end

  describe '#topic' do
    subject { described_class.new(topic_name) }

    let(:topic_name) { 'topic' }
    let(:mock_sns) { double('SNS') }
    let(:response) { double('Aws::SNS::Types::CreateTopicResponse', topic_arn: arn) }
    let(:arn) { 'arn:aws:sns:us-east-1:123456789012:some-topic-name' }

    before do
      allow(subject).to receive(:sns).and_return(mock_sns)
      allow(mock_sns).to receive(:create_topic).with(name: topic_name).and_return(response)
    end

    it 'returns the topic' do
      expect(subject.topic).to be_a Circuitry::Topic
    end

    it 'sets the topic ARN' do
      expect(subject.topic.arn).to eq arn
    end
  end
end
