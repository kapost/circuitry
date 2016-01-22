require 'logger'
require 'virtus'

module Circuitry
  class Configuration
    include Virtus::Model

    attribute :application_name, String
    attribute :queue_prefix, String
    attribute :subscribed_topics, Array[String]

    attribute :access_key, String
    attribute :secret_key, String
    attribute :region, String, default: 'us-east-1'
    attribute :logger, Logger, default: Logger.new(STDERR)
    attribute :error_handler
    attribute :lock_strategy, Object, default: ->(page, attribute) { Circuitry::Locks::Memory.new }
    attribute :publish_async_strategy, Symbol, default: ->(page, attribute) { :fork }
    attribute :subscribe_async_strategy, Symbol, default: ->(page, attribute) { :fork }
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

    def subscriber_queue_name
      [
        application_name,
        queue_prefix,
        "events"
      ].join('-')
    end

    def aws_options
      {
          access_key_id:     access_key,
          secret_access_key: secret_key,
          region:            region,
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
