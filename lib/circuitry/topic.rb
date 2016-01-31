require 'circuitry/services/sns'

module Circuitry
  class Topic
    class Finder
      include Services::SNS

      def initialize(name)
        self.name = name
      end

      def find
        sns.create_topic(name: name)
      end

      private

      attr_accessor :name
    end

    attr_reader :arn

    def initialize(arn)
      @arn = arn
    end

    def self.find(name)
      new(Finder.new(name).find.topic_arn)
    end

    def name
      @name ||= arn.split(':').last
    end

    def ==(other)
      other.hash == hash
    end

    def hash
      [self.class, arn].hash
    end
  end
end
