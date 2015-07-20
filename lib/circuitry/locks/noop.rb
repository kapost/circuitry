module Circuitry
  module Locks
    class NOOP
      include Base

      protected

      def lock(key, ttl)
        true
      end

      def lock!(key, ttl)
        # do nothing
      end
    end
  end
end
