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

      protected

      def lock(key, ttl)
        client.set(key, (Time.now + ttl).to_i, ex: ttl, nx: true)
      end

      def lock!(key, ttl)
        client.set(key, (Time.now + ttl).to_i, ex: ttl)
      end

      private

      attr_accessor :client
    end
  end
end
