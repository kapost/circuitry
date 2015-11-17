require 'circuitry/services/sns'

module Circuitry
  class Topic
    include Services::SNS

    attr_reader :arn

    def initialize(arn)
      @arn = arn
    end

    def name
      @name ||= arn.split(':').last
    end

    def subscribe(queue)
      sns.subscribe(arn, queue.arn, 'sqs').body['SubscriptionArn']
    end

    def ==(obj)
      obj.hash == self.hash
    end

    def hash
      [self.class, arn].hash
    end

    class << self
      include Services::SNS

      def create(name)
        new(sns.create_topic(name).body['TopicArn'])
      end
    end
  end
end
