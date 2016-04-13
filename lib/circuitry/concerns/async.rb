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
        processor = send(:"process_via_#{async}", &block)
        processor.process
        Pool << processor
      end

      def async=(value)
        value = case value
                when false, nil then false
                when true then self.class.default_async_strategy
                when *self.class.async_strategies then value
                else raise ArgumentError, async_value_error(value)
                end

        if value == :fork && !platform_supports_forking?
          raise NotSupportedError, 'Your platform does not support forking'
        end

        @async = value
      end

      def async?
        ![nil, false].include?(async)
      end

      private

      def async_value_error(value)
        options = [true, false].concat(self.class.async_strategies).inspect
        "Invalid value `#{value.inspect}`, must be one of #{options}"
      end

      def platform_supports_forking?
        Process.respond_to?(:fork)
      end

      def process_via_fork(&block)
        Processors::Forker.new(config, &block)
      end

      def process_via_thread(&block)
        Processors::Threader.new(config, &block)
      end

      def process_via_batch(&block)
        Processors::Batcher.new(config, &block)
      end
    end
  end
end
