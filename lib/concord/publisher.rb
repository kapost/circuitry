require 'json'
require 'concord/concerns/async'
require 'concord/services/sns'
require 'concord/topic_creator'

module Concord
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
        logger.warn('Concord unable to publish: AWS configuration is not set.')
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
      Concord.config.logger
    end

    def can_publish?
      Concord.config.aws_options.values.all? do |value|
        !value.nil? && !value.empty?
      end
    end
  end
end
