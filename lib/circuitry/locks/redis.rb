module Circuitry
  module Locks
    class Redis
      include Base

      def initialize(options = {})
        super(options)

        self.client = options.fetch(:client) do
          require 'redis'
          ::Redis.new(options)
        end
      end

      def reap
        # noop
      end

      protected

      def lock(key, timeout)
        client.set(key, Time.now)
        client.expire(key, timeout)
      end

      def release(key)
        client.del(key)
      end

      private

      attr_accessor :client
    end
  end
end
