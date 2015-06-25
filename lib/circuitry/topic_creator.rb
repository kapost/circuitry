require 'circuitry/services/sns'
require 'circuitry/topic'

module Circuitry
  class TopicCreatorError < StandardError; end

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

      response = sns.create_topic(topic_name)
      arn = response.body.fetch('TopicArn') { raise TopicCreatorError.new('No TopicArn returned from SNS') }
      @topic = Topic.new(arn)
    end
  end
end
