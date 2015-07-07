require 'logger'
require 'virtus'

module Circuitry
  class Configuration
    include Virtus::Model

    attribute :access_key, String
    attribute :secret_key, String
    attribute :region, String, default: 'us-east-1'
    attribute :logger, Logger, default: Logger.new(STDERR)
    attribute :error_handler
    attribute :publish_async_strategy, Object, default: :fork
    attribute :subscribe_async_strategy, Object, default: :fork

    def publish_async_strategy=(value)
      unless Concerns::Publisher.async_strategies.include?(value)
        raise ArgumentError, "invalid value `#{value}`, must be one of #{Concerns::Publisher.async_strategies.inspect}"
      end

      super
    end

    def subscribe_async_strategy=(value)
      unless Concerns::Subscriber.async_strategies.include?(value)
        raise ArgumentError, "invalid value `#{value}`, must be one of #{Concerns::Subscriber.async_strategies.inspect}"
      end

      super
    end

    def aws_options
      {
          aws_access_key_id:     access_key,
          aws_secret_access_key: secret_key,
          region:                region,
      }
    end
  end
end
