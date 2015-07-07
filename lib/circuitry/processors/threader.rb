require 'circuitry/processor'

module Circuitry
  module Processors
    module Threader
      extend Processor

      class << self
        def thread(&block)
          raise ArgumentError, 'no block given' unless block_given?
          threads << Thread.new { process(&block) }
        end

        def flush
          threads.each(&:join)
          threads.clear
        end

        private

        def threads
          @threads ||= []
        end
      end
    end
  end
end
