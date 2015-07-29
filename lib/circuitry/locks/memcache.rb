module Circuitry
  module Locks
    class Memcache
      include Base

      def initialize(options = {})
        super(options)

        self.client = options.fetch(:client) do
          require 'dalli'
          ::Dalli::Client.new(options[:host], options)
        end
      end

      protected

      def lock(key, ttl)
        client.add(key, (Time.now + ttl).to_i, ttl)
      end

      def lock!(key, ttl)
        client.set(key, (Time.now + ttl).to_i, ttl)
      end

      def unlock!(key)
        client.delete(key)
      end

      private

      attr_accessor :client
    end
  end
end
