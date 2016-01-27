require 'circuitry/services/sns'
require 'circuitry/topic'

module Circuitry
  class SubscriptionCreator
    include Services::SNS
    include Services::SQS

    attr_reader :queue
    attr_reader :topics

    def self.subscribe_all(queue, topics)
      new(queue, topics).subscribe_all
    end

    def initialize(queue, topics)
      raise ArgumentError, 'queue must be a Circuitry::Queue' unless queue.is_a?(Circuitry::Queue)
      raise ArgumentError, 'topics must be an array' unless topics.is_a?(Array)

      @queue = queue
      @topics = topics
    end

    def subscribe_all
      topics.each do |topic|
        sns.subscribe(topic_arn: topic.arn, endpoint: queue.arn, protocol: 'sqs')
      end
      sqs.set_queue_attributes(
        queue_url: queue.url,
        attributes: build_policy
      )
    end

    private

    def build_policy
      # The aws ruby SDK doesn't have a policy builder :{
      {
        'Policy' => {
          'Version'   => '2012-10-17',
          'Id'        => '#{queue.arn}/SNSPolicy',
          'Statement' => topics.map { |t| build_policy_statement(t) }
        }.to_json
      }
    end

    def build_policy_statement(topic)
      {
        'Sid'       => "Sid#{topic.name}",
        'Effect'    => 'Allow',
        'Principal' => { 'AWS' => '*' },
        'Action'    => 'SQS:SendMessage',
        'Resource'  => queue.arn,
        'Condition' => {
          'ArnEquals' => { 'aws:SourceArn' => topic.arn }
        }
      }
    end
  end
end
