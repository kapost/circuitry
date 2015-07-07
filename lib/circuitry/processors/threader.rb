require 'circuitry/processor'

module Circuitry
  module Processors
    module Threader
      class << self
        include Processor

        def process(&block)
          raise ArgumentError, 'no block given' unless block_given?
          pool << Thread.new { process_entry(&block) }
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
