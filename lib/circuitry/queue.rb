require 'circuitry/services/sqs'

module Circuitry
  class Queue
    include Services::SQS

    attr_reader :url

    def initialize(queue_url)
      @url = queue_url
    end

    def arn
      @arn ||= attribute('QueueArn')
    end

    def policy=(policy)
      policy = Fog::JSON.encode(policy) unless policy.is_a?(String)
      set_attribute('Policy', policy)
    end

    private

    def attribute(name)
      sqs.get_queue_attributes(url, name).body['Attributes'][name]
    end

    def set_attribute(name, value)
      sqs.set_queue_attributes(url, name, value)
    end

    class << self
      include Services::SQS

      def create(name, options)
        new(sqs.create_queue(name, options).body['QueueUrl'])
      end
    end
  end
end
