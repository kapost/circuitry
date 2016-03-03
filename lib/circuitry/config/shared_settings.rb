require 'logger'

module Circuitry
  class ConfigError < StandardError; end

  module Config
    module SharedSettings
      def self.included(base)
        base.attribute :access_key, String
        base.attribute :secret_key, String
        base.attribute :region, String, default: 'us-east-1'
        base.attribute :logger, Logger, default: Logger.new(STDERR)
        base.attribute :error_handler
        base.attribute :topic_names, Array[String], default: []
        base.attribute :on_async_exit
        base.attribute :async_strategy, Symbol, default: ->(_page, _att) { :fork }
      end

      def middleware
        @_middleware ||= Middleware::Chain.new
        yield @_middleware if block_given?
        @_middleware
      end

      def aws_options
        {
          access_key_id:     access_key,
          secret_access_key: secret_key,
          region:            region
        }
      end

      def validate_setting(value, permitted_values)
        return if permitted_values.include?(value)
        raise ConfigError, "invalid value `#{value}`, must be one of #{permitted_values.inspect}"
      end
    end
  end
end
