require 'circuitry/services/sqs'
require 'circuitry/queue'

module Circuitry
  class QueueCreator
    include Services::SQS

    attr_reader :queue_name, :attributes

    def self.find_or_create(queue_name, attributes = {})
      new(queue_name, attributes).queue
    end

    def initialize(queue_name, attributes = {})
      @queue_name = queue_name
      @attributes = attributes
    end

    def queue
      return @queue if defined?(@queue)

      response = sqs.create_queue(queue_name: queue_name, attributes: attributes)
      @queue = Queue.new(response.queue_url)
    end
  end
end
