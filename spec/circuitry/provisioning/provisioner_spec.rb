require 'spec_helper'

RSpec.describe Circuitry::Provisioning::Provisioner do
  subject { described_class.new(logger) }

  let(:logger) { double('Logger', info: nil, fatal: nil) }

  describe '#run' do
    let(:queue) { Circuitry::Queue.new('my_queue_name') }
    let(:topic) { Circuitry::Topic.new('my_topic_arn') }

    before do
      Circuitry.subscriber_config.topic_names = %w[my_topic_name1 my_topic_name2]
      Circuitry.publisher_config.topic_names = %w[my_sub_topic_name]

      allow(Circuitry::Provisioning::QueueCreator).to receive(:find_or_create).and_return(queue)
      allow(Circuitry::Provisioning::TopicCreator).to receive(:find_or_create).and_return(topic)
      allow(Circuitry::Provisioning::SubscriptionCreator).to receive(:subscribe_all).and_return(true)

    end

    describe 'when queue name is set' do
      before do
        Circuitry.subscriber_config.queue_name = 'my_queue_name'
        subject.run
      end

      it 'creates a queue' do
        expect(Circuitry::Provisioning::QueueCreator).to have_received(:find_or_create).once.with(Circuitry.subscriber_config.queue_name,
          dead_letter_queue_name: 'my_queue_name-failures',
          visibility_timeout: Circuitry.subscriber_config.visibility_timeout,
          max_receive_count: Circuitry.subscriber_config.max_receive_count
        )
      end

      it 'creates publisher topics' do
        expect(Circuitry::Provisioning::TopicCreator).to have_received(:find_or_create).once.with('my_sub_topic_name')
      end

      it 'creates subscriber topics' do
        expect(Circuitry::Provisioning::TopicCreator).to have_received(:find_or_create).once.with('my_topic_name1')
        expect(Circuitry::Provisioning::TopicCreator).to have_received(:find_or_create).once.with('my_topic_name2')
      end

      it 'subscribes subscriber topics to queue' do
        expect(Circuitry::Provisioning::SubscriptionCreator).to have_received(:subscribe_all).once.with(queue, [topic, topic])
      end
    end

    describe 'when queue name is not set' do
      before do
        Circuitry.subscriber_config.queue_name = nil
        subject.run
      end

      it 'does not create a queue' do
        expect(Circuitry::Provisioning::QueueCreator).to_not have_received(:find_or_create)
      end

      it 'creates publisher topics' do
        expect(Circuitry::Provisioning::TopicCreator).to have_received(:find_or_create).once.with('my_sub_topic_name')
      end

      it 'does not create subscriber topics' do
        expect(Circuitry::Provisioning::TopicCreator).to_not have_received(:find_or_create).with('my_topic_name1')
        expect(Circuitry::Provisioning::TopicCreator).to_not have_received(:find_or_create).with('my_topic_name2')
      end

      it 'does not subscribe subscriber topics to queue' do
        expect(Circuitry::Provisioning::SubscriptionCreator).to_not have_received(:subscribe_all)
      end
    end
  end
end
