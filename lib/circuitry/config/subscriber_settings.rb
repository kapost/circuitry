require 'virtus'
require 'circuitry/config/shared_settings'

module Circuitry
  module Config
    class SubscriberSettings
      include Virtus::Model
      include SharedSettings

      attribute :queue_name, String
      attribute :dead_letter_queue_name, String
      attribute :visibility_timeout, Integer, default: 30 * 60
      attribute :max_receive_count, Integer, default: 8
      attribute :lock_strategy, Object, default: ->(_page, _att) { Circuitry::Locks::Memory.new }

      def dead_letter_queue_name
        super || "#{queue_name}-failures"
      end

      def async_strategy=(value)
        validate_setting(value, Subscriber.async_strategies)
        super
      end

      def lock_strategy=(value)
        unless value.is_a?(Circuitry::Locks::Base)
          raise ConfigError, "invalid lock strategy \"#{value.inspect}\""
        end
        super
      end
    end
  end
end
