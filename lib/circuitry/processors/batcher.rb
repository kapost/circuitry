require 'circuitry/processor'

module Circuitry
  module Processors
    class Batcher < Processor
      def process
        # noop
      end

      def wait
        safely_process(&block)
      end
    end
  end
end
