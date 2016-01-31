require 'circuitry/services/sqs'

module Circuitry
  class Queue
    class Finder
      include Services::SQS

      def initialize(name)
        @name = name
      end

      def find
        sqs.get_queue_url(queue_name: name)
      end

      private

      attr_accessor :name
    end

    attr_reader :url

    def initialize(url)
      @url = url
    end

    def self.find(name)
      new(Finder.new(name).find.queue_url)
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
