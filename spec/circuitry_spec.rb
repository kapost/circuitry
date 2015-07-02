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
    it 'delegates to a new subscriber' do
      subscriber = double('Subscriber', subscribe: true)
      queue = 'https://sqs.amazon.com/account/queue'
      block = -> { }
      options = { foo: 'bar' }

      allow(Circuitry::Subscriber).to receive(:new).with(queue, options).and_return(subscriber)
      subject.subscribe(queue, options, &block)
      expect(subscriber).to have_received(:subscribe).with(no_args, &block)
    end
  end

  describe '.flush' do
    pending
  end
end
