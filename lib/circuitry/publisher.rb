require 'json'
require 'circuitry/concerns/async'
require 'circuitry/services/sns'

module Circuitry
  class PublishError < StandardError; end

  class Publisher
    include Concerns::Async
    include Services::SNS

    DEFAULT_OPTIONS = {
      async: false
    }.freeze

    def initialize(options = {})
      options = DEFAULT_OPTIONS.merge(options)
      self.async = options[:async]
    end

    def publish(topic_name, object)
      raise ArgumentError, 'topic_name cannot be nil' if topic_name.nil?
      raise ArgumentError, 'object cannot be nil' if object.nil?
      raise PublishError, 'AWS configuration is not set' unless can_publish?

      message = object.to_json

      if async?
        process_asynchronously { publish_internal(topic_name, message) }
      else
        publish_internal(topic_name, message)
      end
    end

    def self.default_async_strategy
      Circuitry.publisher_config.async_strategy
    end

    protected

    def publish_internal(topic_name, message)
      middleware.invoke(topic_name, message) do
        logger.info("Publishing message to #{topic_name}")

        topic = Topic.find(topic_name)
        sns.publish(topic_arn: topic.arn, message: message)
      end
    end

    private

    def logger
      Circuitry.publisher_config.logger
    end

    def can_publish?
      Circuitry.publisher_config.aws_options.values.all? do |value|
        !value.nil? && !value.empty?
      end
    end

    def middleware
      Circuitry.publisher_config.middleware
    end
  end
end
