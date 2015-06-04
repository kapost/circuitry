require 'concord/services/sns'
require 'concord/topic_creator'

module Concord
  class PublishError < StandardError; end

  class Publisher
    include Services::SNS

    attr_reader :topic_name, :object, :options

    def initialize(topic_name, object, options = {})
      raise ArgumentError('topic_name cannot be nil') if topic_name.nil?
      raise ArgumentError('object cannot be nil') if object.nil?

      @topic_name = topic_name
      @object = object
      @options = options
    end

    def publish
      sns.publish(topic.arn, object.to_json)
    end

    private

    def topic
      @topic ||= TopicCreator.find_or_create(topic_name)
    end

    def logger
      Concord.config.logger
    end
  end
end
