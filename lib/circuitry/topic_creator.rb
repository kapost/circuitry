require 'circuitry/services/sns'
require 'circuitry/topic'

module Circuitry
  class TopicCreator
    include Services::SNS

    attr_reader :topic_name

    def self.find_or_create(topic_name)
      new(topic_name).topic
    end

    def initialize(topic_name)
      @topic_name = topic_name
    end

    def topic
      return @topic if defined?(@topic)

      response = sns.create_topic(name: topic_name)
      @topic = Topic.new(response.topic_arn)
    end
  end
end
