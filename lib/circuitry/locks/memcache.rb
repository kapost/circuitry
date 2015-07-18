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

      def reap
        # noop
      end

      protected

      def lock(key, timeout)
        client.set(key, Time.now, timeout)
      end

      def release(key)
        client.delete(key)
      end

      private

      attr_accessor :client
    end
  end
end
