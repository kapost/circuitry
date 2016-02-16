require 'spec_helper'

RSpec.describe Circuitry::CLI do
  subject { described_class }

  describe '#provision' do
    before do
      allow(Circuitry::Provisioning::QueueCreator).to receive(:find_or_create).and_return(queue)
      allow(Circuitry::Provisioning::TopicCreator).to receive(:find_or_create).and_return(topic)
      allow(Circuitry::Provisioning::SubscriptionCreator).to receive(:subscribe_all).and_return(true)

      subject.start(command.split)
    end

    let(:queue) { Circuitry::Queue.new('http://sqs.amazontest.com/example') }
    let(:topic) { Circuitry::Topic.new('arn:aws:sns:us-east-1:123456789012:some-topic-name') }

    describe 'vanilla command' do
      let(:command) { 'provision example -t topic1 topic2 -a 123 -s 123 -r us-east-1' }

      it 'creates primary and dead letter queues' do
        expect(Circuitry::Provisioning::QueueCreator).to have_received(:find_or_create).once.with('example', hash_including(dead_letter_queue_name: 'example-failures'))
      end

      it 'creates each topic' do
        expect(Circuitry::Provisioning::TopicCreator).to have_received(:find_or_create).twice
      end

      it 'subscribes to all topics' do
        expect(Circuitry::Provisioning::SubscriptionCreator).to have_received(:subscribe_all).once.with(queue, [topic, topic])
      end
    end

    describe 'no queue given' do
      let(:command) { 'provision' }

      it 'does nothing' do
        expect(Circuitry::Provisioning::QueueCreator).to_not have_received(:find_or_create)
      end
    end

    describe 'no topics given' do
      let(:command) { 'provision example' }

      it 'does not create queue' do
        expect(Circuitry::Provisioning::QueueCreator).to_not have_received(:find_or_create)
      end

      it 'does not create topics' do
        expect(Circuitry::Provisioning::TopicCreator).to_not have_received(:find_or_create)
      end
    end
  end
end
