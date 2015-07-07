require 'circuitry/processors/batcher'
require 'circuitry/processors/forker'
require 'circuitry/processors/threader'

module Circuitry
  class NotSupportedError < StandardError; end

  module Concerns
    module Async
      attr_reader :async

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def async_strategies
          [:fork, :thread, :batch]
        end

        def default_async_strategy
          raise NotImplementedError, "#{name} must implement class method `default_async_strategy`"
        end
      end

      def process_asynchronously(&block)
        send(:"process_via_#{async}", &block)
      end

      def async=(value)
        value = case value
          when false, nil then false
          when true then self.class.default_async_strategy
          when *self.class.async_strategies then value
          else raise ArgumentError, "Invalid value `#{value.inspect}`, must be one of #{[true, false].concat(self.class.async_strategies).inspect}"
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

      def platform_supports_forking?
        Process.respond_to?(:fork)
      end

      def process_via_fork(&block)
        Processors::Forker.process(&block)
      end

      def process_via_thread(&block)
        Processors::Threader.process(&block)
      end

      def process_via_batch(&block)
        Processors::Batcher.process(&block)
      end
    end
  end
end
