require 'spec_helper'

RSpec.describe Circuitry::Queue, type: :model do
  subject { described_class.new(url) }

  let(:url) { 'https://sqs.amazontest.com/123/queue_name' }

  describe '.find' do
    subject { described_class }

    before do
      allow_any_instance_of(Circuitry::Queue::Finder).to receive(:find).and_return(double('Queue', queue_url: url))
    end

    it 'returns a queue object' do
      expect(subject.find('queue_name')).to be_instance_of(Circuitry::Queue)
    end
  end

  describe '#name' do
    it 'returns last segment of url' do
      expect(subject.name).to eql('queue_name')
    end
  end
end
