require 'circuitry/processor'

module Circuitry
  module Processors
    class Forker < Processor
      def process
        Process.detach(pid)
      end

      def wait
        # noop
      end

      private

      def pid
        @pid ||= fork do
          safely_process(&block)
        end
      end
    end
  end
end
