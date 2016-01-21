require 'json'
require 'timeout'
require 'circuitry/concerns/async'
require 'circuitry/services/sns'
require 'circuitry/topic_creator'

module Circuitry
  class PublishError < StandardError; end

  class Publisher
    include Concerns::Async
    include Services::SNS

    DEFAULT_OPTIONS = {
        async: false,
        timeout: 15,
    }.freeze

    attr_reader :timeout

    def initialize(options = {})
      options = DEFAULT_OPTIONS.merge(options)

      self.async = options[:async]
      self.timeout = options[:timeout]
    end

    def publish(topic_name, object)
      raise ArgumentError.new('topic_name cannot be nil') if topic_name.nil?
      raise ArgumentError.new('object cannot be nil') if object.nil?
      raise PublishError.new('AWS configuration is not set') unless can_publish?

      process = -> do
        Timeout.timeout(timeout) do
          logger.info("Publishing message to #{topic_name}")

          topic = TopicCreator.find_or_create(topic_name)
          sns.publish(topic_arn: topic.arn, message: object.to_json)
        end
      end

      if async?
        process_asynchronously(&process)
      else
        process.call
      end
    end

    def self.default_async_strategy
      Circuitry.config.publish_async_strategy
    end

    protected

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
  end
end
