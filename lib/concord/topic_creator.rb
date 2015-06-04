require 'concord/services/sns'
require 'concord/topic'

module Concord
  class TopicCreatorError < StandardError; end

  class TopicCreator
    include Services::SNS

    attr_reader :topic_name

    def self.find_or_create(topic_name)
      new(topic_name).find_or_create
    end

    def initialize(topic_name)
      @topic_name = topic_name
    end

    def find_or_create
      return @topic if defined?(@topic)

      response = sns.create_topic(topic_name)
      arn = response.body.fetch('TopicArn') { raise TopicCreatorError.new('No TopicArn returned from SNS') }
      @topic = Topic.new(arn)
    end
  end
end
