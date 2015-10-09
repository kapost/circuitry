require 'circuitry/processor'

module Circuitry
  module Processors
    module Forker
      class << self
        include Processor

        def process(&block)
          pid = fork do
            safely_process(&block)
            Circuitry.config.on_fork_exit.call if Circuitry.config.on_fork_exit
          end

          Process.detach(pid)
        end

        def flush
        end
      end
    end
  end
end
