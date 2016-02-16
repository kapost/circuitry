require 'spec_helper'

RSpec.describe Circuitry::Provisioning do
  subject { described_class }

  let(:queue) { Circuitry::Queue.new('my_queue_name') }
  let(:topic) { Circuitry::Topic.new('my_topic_arn') }

  describe '.provision' do
    before do
      Circuitry.subscriber_config.queue_name = 'my_queue_name'
      Circuitry.subscriber_config.topic_names = ['my_topic_name1', 'my_topic_name2']
      Circuitry.publisher_config.topic_names = ['my_sub_topic_name']

      allow(Circuitry::Provisioning::QueueCreator).to receive(:find_or_create).and_return(queue)
      allow(Circuitry::Provisioning::TopicCreator).to receive(:find_or_create).and_return(topic)
      allow(Circuitry::Provisioning::SubscriptionCreator).to receive(:subscribe_all).and_return(true)

      subject.provision
    end

    it 'creates queues from config' do
      expect(Circuitry::Provisioning::QueueCreator).to have_received(:find_or_create).once.with(Circuitry.subscriber_config.queue_name, hash_including(:dead_letter_queue_name => 'my_queue_name-failures'))
    end

    it 'creates each publishing topics from config' do
      expect(Circuitry::Provisioning::TopicCreator).to have_received(:find_or_create).once.with('my_topic_name1')
      expect(Circuitry::Provisioning::TopicCreator).to have_received(:find_or_create).once.with('my_topic_name2')
    end

    it 'create subscriber topics from config' do
      expect(Circuitry::Provisioning::TopicCreator).to have_received(:find_or_create).once.with('my_sub_topic_name')
    end

    it 'subscribe created subscriber topics to created queue' do
      expect(Circuitry::Provisioning::SubscriptionCreator).to have_received(:subscribe_all).once.with(queue, [topic, topic])
    end
  end
end
