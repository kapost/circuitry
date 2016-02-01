require 'logger'
require 'virtus'

module Circuitry
  class Configuration
    include Virtus::Model

    attribute :subscriber_queue_name, String
    attribute :subscriber_dead_letter_queue_name, String
    attribute :publisher_topic_names, Array[String], default: []
    attribute :subscriber_topic_names, Array[String], default: []

    attribute :access_key, String
    attribute :secret_key, String
    attribute :region, String, default: 'us-east-1'
    attribute :logger, Logger, default: Logger.new(STDERR)
    attribute :error_handler
    attribute :lock_strategy, Object, default: ->(_page, _attribute) { Circuitry::Locks::Memory.new }
    attribute :publish_async_strategy, Symbol, default: ->(_page, _attribute) { :fork }
    attribute :subscribe_async_strategy, Symbol, default: ->(_page, _attribute) { :fork }
    attribute :on_thread_exit
    attribute :on_fork_exit

    def publish_async_strategy=(value)
      validate(value, Publisher.async_strategies)
      super
    end

    def subscribe_async_strategy=(value)
      validate(value, Subscriber.async_strategies)
      super
    end

    def subscriber_dead_letter_queue_name
      super || "#{subscriber_queue_name}-failures"
    end

    def subscriber_middleware
      @subscriber_middleware ||= Circuitry::Middleware::Chain.new
      yield @subscriber_middleware if block_given?
      @subscriber_middleware
    end

    def publisher_middleware
      @publisher_middleware ||= Circuitry::Middleware::Chain.new
      yield @publisher_middleware if block_given?
      @publisher_middleware
    end

    def aws_options
      {
        access_key_id:     access_key,
        secret_access_key: secret_key,
        region:            region
      }
    end

    private

    def validate(value, permitted_values)
      return if permitted_values.include?(value)
      raise ArgumentError, "invalid value `#{value}`, must be one of #{permitted_values.inspect}"
    end
  end
end
