require 'circuitry/processor'

module Circuitry
  module Processors
    class Threader < Processor
      def process
        thread
      end

      def wait
        thread.join
      end

      private

      def thread
        @thread ||= Thread.new do
          safely_process(&block)
        end
      end
    end
  end
end
