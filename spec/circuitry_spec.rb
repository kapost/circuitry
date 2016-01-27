require 'spec_helper'

RSpec.describe Circuitry, type: :model do
  subject { described_class }

  describe '.config' do
    it 'returns a configuration object' do
      expect(subject.config).to be_a Circuitry::Configuration
    end

    it 'always returns the same object' do
      expect(subject.config).to be subject.config
    end

    it 'accepts a block' do
      expect {
        subject.config { |c| c.access_key = 'foo' }
      }.to change { subject.config.access_key }.to('foo')
    end
  end

  describe '.publish' do
    it 'delegates to a new publisher' do
      publisher = double('Publisher', publish: true)
      topic = 'topic-name'
      object = double('Object')
      options = { foo: 'bar' }

      allow(Circuitry::Publisher).to receive(:new).with(options).and_return(publisher)
      subject.publish(topic, object, options)
      expect(publisher).to have_received(:publish).with(topic, object)
    end
  end

  describe '.subscribe' do
    let(:subscriber) { double('Subscriber', subscribe: true) }
    let(:queue) { 'https://sqs.amazon.com/account/queue' }
    let(:options) { { foo: 'bar' } }

    before do
      allow(Circuitry::Subscriber).to receive(:new).with(options).and_return(subscriber)
      allow(Circuitry::QueueCreator).to receive(:find_or_create).and_return(double('Queue', url: queue))
    end

    it 'delegates to a new subscriber' do
      block = -> {}
      subject.subscribe(options, &block)
      expect(subscriber).to have_received(:subscribe).with(no_args, &block)
    end
  end

  describe '.flush' do
    it 'flushes batches' do
      expect(Circuitry::Processors::Batcher).to receive(:flush)
      subject.flush
    end

    it 'flushes forks' do
      expect(Circuitry::Processors::Forker).to receive(:flush)
      subject.flush
    end

    it 'flushes threads' do
      expect(Circuitry::Processors::Threader).to receive(:flush)
      subject.flush
    end
  end
end
