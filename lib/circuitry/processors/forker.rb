require 'circuitry/processor'

module Circuitry
  module Processors
    module Forker
      class << self
        include Processor

        def process(&block)
          pid = fork { safely_process(&block) }
          Process.detach(pid)
        end

        def flush
        end
      end
    end
  end
end
