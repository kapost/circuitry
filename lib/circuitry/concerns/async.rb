module Circuitry
  class NotSupportedError < StandardError; end

  module Concerns
    module Async
      STRATEGIES = [:fork, :thread, :batch].freeze

      attr_reader :async

      def process_asynchronously(&block)
        public_send(:"process_via_#{async}", &block)
      end

      def async=(value)
        value = Circuitry.config.async_strategy if value === true
        value = false if value.nil?

        unless STRATEGIES.include?(value) || value === false
          raise ArgumentError, "Invalid value `#{value.inspect}`, must be one of #{[true, false].concat(STRATEGIES).inspect}"
        end

        if value == :fork && !platform_supports_forking?
          raise NotSupportedError, 'Your platform does not support forking'
        end

        @async = value
      end

      def async?
        !!async
      end

      private

      def process_via_fork(&block)
        pid = fork(&block)
        Process.detach(pid)
      end

      def process_via_thread(&block)
        Thread.new(&block)
      end

      def process_via_batch(&block)
        Batcher.batch(&block)
      end

      def platform_supports_forking?
        Process.respond_to?(:fork)
      end
    end
  end
end
