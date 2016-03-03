require 'circuitry/processor'

module Circuitry
  module Processors
    module Batcher
      class << self
        include Processor

        def process(&block)
          raise ArgumentError, 'no block given' unless block_given?
          pool << block
        end

        def flush
          while (block = pool.shift)
            safely_process(&block)
          end
        end
      end
    end
  end
end
