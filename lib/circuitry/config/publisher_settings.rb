require 'virtus'
require 'circuitry/config/shared_settings'

module Circuitry
  module Config
    class PublisherSettings
      include Virtus::Model
      include SharedSettings

      def async_strategy=(value)
        validate_setting(value, Publisher.async_strategies)
        super
      end
    end
  end
end
