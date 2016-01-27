require 'json'
require 'spec_helper'

RSpec::Matchers.define :policy_statement_count_matcher do |count|
  match do |actual|
    JSON.parse(actual[:attributes]['Policy'])['Statement'].length == count
  end
end

RSpec.describe Circuitry::SubscriptionCreator do
  describe '.subscribe_all' do
    subject { described_class }

    before do
      allow_any_instance_of(subject).to receive(:sqs).and_return(mock_sqs)
      allow_any_instance_of(subject).to receive(:sns).and_return(mock_sns)
      allow(queue).to receive(:arn).and_return(queue_arn)
    end

    let(:mock_sns) { double('SNS', subscribe: true) }
    let(:mock_sqs) { double('SQS', set_queue_attributes: true) }

    let(:topics) { (1..3).map { |index| Circuitry::Topic.new("arn:aws:sns:us-east-1:123456789012:some-topic-name#{index+1}") } }
    let(:queue) { Circuitry::Queue.new('http://amazontest.com/howdy') }
    let(:queue_arn) { 'arn:aws:sqs:us-east-1:123456789012:howdy' }

    it 'subscribes each topic to the queue' do
      subject.subscribe_all(queue, topics)
      expect(mock_sns).to have_received(:subscribe).thrice.with(hash_including(endpoint: queue_arn, protocol: 'sqs'))
    end

    it 'sets policy attribute on sqs queue for each topic' do
      subject.subscribe_all(queue, topics)
      expect(mock_sqs).to have_received(:set_queue_attributes).once.with(policy_statement_count_matcher(3))
    end
  end
end
