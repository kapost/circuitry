require 'json'
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
    }.freeze

    def initialize(options = {})
      options = DEFAULT_OPTIONS.merge(options)

      @async = !!options[:async]
    end

    def publish(topic_name, object)
      raise ArgumentError.new('topic_name cannot be nil') if topic_name.nil?
      raise ArgumentError.new('object cannot be nil') if object.nil?

      unless can_publish?
        logger.warn('Circuitry unable to publish: AWS configuration is not set.')
        return
      end

      process = -> do
        topic = TopicCreator.find_or_create(topic_name)
        sns.publish(topic.arn, object.to_json)
      end

      if async?
        process_asynchronously(&process)
      else
        process.call
      end
    end

    def async?
      @async
    end

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
