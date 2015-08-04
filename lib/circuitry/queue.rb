require 'circuitry/services/sqs'

module Circuitry
  class Queue
    include Services::SQS

    attr_reader :url

    def initialize(url)
      @url = url
    end

    def name
      url.split('/').last
    end

    def arn
      @arn ||= attribute('QueueArn')
    end

    def policy=(policy)
      set_attribute('Policy', encode(policy))
    end

    def redrive_policy=(policy)
      set_attribute('RedrivePolicy', encode(policy))
    end

    private

    def attribute(name)
      sqs.get_queue_attributes(url, name).body['Attributes'][name]
    end

    def set_attribute(name, value)
      sqs.set_queue_attributes(url, name, value)
    end

    def encode(value)
      value.is_a?(String) ? value : Fog::JSON.encode(value)
    end

    class << self
      include Services::SQS

      def create(name, options = {})
        new(sqs.create_queue(name, options).body['QueueUrl'])
      end
    end
  end
end
