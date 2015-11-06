module Circuitry
  class Topic
    attr_reader :arn

    def initialize(arn)
      @arn = arn
    end

    def name
      @name ||= arn.split(':').last
    end

    def ==(obj)
      obj.hash == self.hash
    end

    def hash
      [self.class, arn].hash
    end
  end
end
