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

    CONNECTION_ERRORS = [
      ::Seahorse::Client::NetworkingError,
      ::Aws::SNS::Errors::InternalFailure
    ].freeze

    attr_reader :config, :timeout

    def initialize(options = {})
      options = DEFAULT_OPTIONS.merge(options)

      self.config = options[:config] || Circuitry.publisher_config
      self.async = options[:async]
      self.timeout = options[:timeout]
    end

    def publish(topic_name, object)
      raise ArgumentError, 'topic_name cannot be nil' if topic_name.nil?
      raise ArgumentError, 'object cannot be nil' if object.nil?
      raise PublishError, 'AWS configuration is not set' unless can_publish?

      message = object.to_json

      if async?
        process_asynchronously { publish_message(topic_name, message) }
      else
        publish_message(topic_name, message)
      end
    end

    protected

    def publish_message(topic_name, message)
      middleware.invoke(topic_name, message) do
        # TODO: Don't use ruby timeout.
        # http://www.mikeperham.com/2015/05/08/timeout-rubys-most-dangerous-api/
        Timeout.timeout(timeout) do
          logger.info("Publishing message to #{topic_name}")

          handler = ->(error, attempt_number, _total_delay) do
            logger.warn("Error publishing attempt ##{attempt_number}: #{error.class} (#{error.message}); retrying...")
          end

          with_retries(max_tries: 3, handler: handler, rescue: CONNECTION_ERRORS, base_sleep_seconds: 0.05, max_sleep_seconds: 0.25) do
            topic = Topic.find(topic_name)
            sns.publish(topic_arn: topic.arn, message: message)
          end
        end
      end
    end

    private

    attr_writer :config, :timeout

    def logger
      config.logger
    end

    def can_publish?
      config.aws_options.values.all? do |value|
        !value.nil? && !value.empty?
      end
    end

    def middleware
      config.middleware
    end
  end
end
