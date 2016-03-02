require 'circuitry'

module Circuitry
  class Publisher
    def publish(_topic_name, _object)
      # noop
    end
  end

  class Subscriber
    def subscribe(&_block)
      # noop
    end
  end
end
