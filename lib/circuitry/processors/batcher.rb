require 'circuitry/processor'

module Circuitry
  module Processors
    module Batcher
      extend Processor

      class << self
        def batch(&block)
          raise ArgumentError, 'no block given' unless block_given?
          batches << block
        end

        def flush
          batches.each(&method(:process))
          batches.clear
        end

        private

        def batches
          @batches ||= []
        end
      end
    end
  end
end
