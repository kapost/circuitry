require 'circuitry/processor'

module Circuitry
  module Processors
    module Threader
      class << self
        include Processor

        def process(&block)
          raise ArgumentError, 'no block given' unless block_given?
          pool << Thread.new { safely_process(&block) }
        end

        def flush
          pool.each(&:join)
        ensure
          pool.clear
        end
      end
    end
  end
end
