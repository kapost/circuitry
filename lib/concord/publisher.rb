require 'json'
require 'concord/services/sns'
require 'concord/topic_creator'

module Concord
  class PublishError < StandardError; end

  class Publisher
    include Services::SNS

    def initialize(options = {})
      # We're not utilizing `options` at the moment, but let's leave it here for
      # conformity with the `Subscriber` class while allowing for future
      # enhancement that does not disturb this method's signature.
    end

    def publish(topic_name, object)
      raise ArgumentError.new('topic_name cannot be nil') if topic_name.nil?
      raise ArgumentError.new('object cannot be nil') if object.nil?

      unless can_publish?
        logger.warn('Concord unable to publish: AWS configuration is not set.')
        return
      end

      topic = TopicCreator.find_or_create(topic_name)
      sns.publish(topic.arn, object.to_json)
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
