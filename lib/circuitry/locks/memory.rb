module Circuitry
  module Locks
    class Memory
      include Base

      class << self
        def store
          @store ||= {}
        end
      end

      def reap
        now = Time.now
        store.delete_if { |key, expires_at| expires_at < now }
      end

      protected

      def lock(key, ttl)
        store[key] = Time.now + ttl
      end

      def expires_at(key)
        store[key]
      end

      private

      def store
        self.class.store
      end
    end
  end
end
