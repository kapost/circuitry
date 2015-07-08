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
          pool.each { |block| safely_process(&block) }
        ensure
          pool.clear
        end
      end
    end
  end
end
