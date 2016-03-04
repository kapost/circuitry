module Circuitry
  module Middleware
    module Entries
      class Flush
        def initialize(_options = {})
        end

        def call(_topic, _message)
          yield
        ensure
          Circuitry.flush
        end
      end
    end
  end
end
