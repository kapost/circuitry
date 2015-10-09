require 'circuitry/processor'

module Circuitry
  module Processors
    module Threader
      class << self
        include Processor

        def process(&block)
          raise ArgumentError, 'no block given' unless block_given?

          pool << Thread.new do
            safely_process(&block)
            Circuitry.config.on_thread_exit.call if Circuitry.config.on_thread_exit
          end
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
