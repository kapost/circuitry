module Circuitry
  module Locks
    class NOOP
      include Base

      protected

      def lock(_key, _ttl)
        true
      end

      def lock!(key, ttl)
        # do nothing
      end

      def unlock!(key)
        # do nothing
      end
    end
  end
end
