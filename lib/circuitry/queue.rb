require 'circuitry/services/sqs'

module Circuitry
  class Queue
    class Finder
      include Services::SQS

      def initialize(name)
        self.name = name
      end

      def find
        sqs.get_queue_url(queue_name: name)
      end

      private

      attr_accessor :name
    end

    attr_reader :url

    def initialize(url)
      self.url = url
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

    def attribute(name)
      sqs.get_queue_attributes(queue_url: url, attribute_names: [name]).attributes[name]
    end

    private

    attr_writer :url
  end
end
