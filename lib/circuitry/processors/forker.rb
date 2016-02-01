require 'circuitry/processor'

module Circuitry
  module Processors
    module Forker
      class << self
        include Processor

        def process(&block)
          pid = fork do
            safely_process(&block)
            on_exit.call if on_exit
          end

          Process.detach(pid)
        end

        def flush
        end
      end
    end
  end
end
