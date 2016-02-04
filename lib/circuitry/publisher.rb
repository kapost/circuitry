require 'json'
require 'timeout'
require 'circuitry/concerns/async'
require 'circuitry/services/sns'

module Circuitry
  class PublishError < StandardError; end

  class Publisher
    include Concerns::Async
    include Services::SNS

    DEFAULT_OPTIONS = {
      async: false,
      timeout: 15
    }.freeze

    attr_reader :timeout

    def initialize(options = {})
      options = DEFAULT_OPTIONS.merge(options)

      self.async = options[:async]
      self.timeout = options[:timeout]
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
      Circuitry.config.publish_async_strategy
    end

    protected

    def publish_internal(topic_name, message)
      middleware.invoke(topic_name, message) do
        # TODO: Don't use ruby timeout.
        # http://www.mikeperham.com/2015/05/08/timeout-rubys-most-dangerous-api/
        Timeout.timeout(timeout) do
          logger.info("Publishing message to #{topic_name}")

          topic = Topic.find(topic_name)
          sns.publish(topic_arn: topic.arn, message: message)
        end
      end
    end

    attr_writer :timeout

    private

    def logger
      Circuitry.config.logger
    end

    def can_publish?
      Circuitry.config.aws_options.values.all? do |value|
        !value.nil? && !value.empty?
      end
    end

    def middleware
      Circuitry.config.publisher_middleware
    end
  end
end
