module Concord
  class Topic
    attr_reader :arn

    def initialize(arn)
      @arn = arn
    end
  end
end
