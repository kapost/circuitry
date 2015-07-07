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
    attribute :publish_async_strategy, Symbol, default: ->(page, attribute) { :fork }
    attribute :subscribe_async_strategy, Symbol, default: ->(page, attribute) { :fork }

    def publish_async_strategy=(value)
      validate(value, Publisher.async_strategies)
      super
    end

    def subscribe_async_strategy=(value)
      validate(value, Subscriber.async_strategies)
      super
    end

    def aws_options
      {
          aws_access_key_id:     access_key,
          aws_secret_access_key: secret_key,
          region:                region,
      }
    end

    private

    def validate(value, permitted_values)
      unless permitted_values.include?(value)
        raise ArgumentError, "invalid value `#{value}`, must be one of #{permitted_values.inspect}"
      end
    end
  end
end
