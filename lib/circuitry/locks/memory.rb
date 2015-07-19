module Circuitry
  module Locks
    class Memory
      include Base

      class << self
        def store
          @store ||= {}
        end

        def semaphore
          @semaphore ||= Mutex.new
        end
      end

      protected

      def lock(key, ttl)
        reap

        store do |store|
          if store.has_key?(key)
            false
          else
            store[key] = Time.now + ttl
            true
          end
        end
      end

      def lock!(key, ttl)
        reap

        store do |store|
          store[key] = Time.now + ttl
        end
      end

      private

      def store(&block)
        semaphore.synchronize do
          block.call(self.class.store)
        end
      end

      def reap
        store do |store|
          now = Time.now
          store.delete_if { |key, expires_at| expires_at <= now }
        end
      end

      def semaphore
        self.class.semaphore
      end
    end
  end
end
