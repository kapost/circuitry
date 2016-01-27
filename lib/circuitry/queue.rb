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

    private

    def attribute(name)
      sqs.get_queue_attributes(queue_url: url, attribute_names: [name]).attributes[name]
    end
  end
end
