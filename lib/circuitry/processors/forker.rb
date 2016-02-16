require 'circuitry/processor'

module Circuitry
  module Processors
    module Forker
      class << self
        include Processor

        def process(&block)
          on_exit = Circuitry.subscriber_config.on_fork_exit

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
