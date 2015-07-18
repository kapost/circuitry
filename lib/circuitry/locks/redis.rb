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

      def lock(key, ttl)
        client.set(key, (Time.now + timeout).to_i)
        client.expire(key, ttl)
      end

      def expires_at(key)
        expires_at = client.get(key)
        expires_at && Time.at(expires_at)
      end

      private

      attr_accessor :client
    end
  end
end
