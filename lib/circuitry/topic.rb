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
      sns.subscribe(topic_arn: arn, endpoint: queue.arn, protocol: 'sqs').subscription_arn
    end

    def ==(obj)
      obj.hash == self.hash
    end

    def hash
      [self.class, arn].hash
    end
  end
end
