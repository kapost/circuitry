require 'json'
require 'circuitry/topic'

module Circuitry
  class Message
    attr_reader :sqs_message

    def initialize(sqs_message)
      @sqs_message = sqs_message
    end

    def context
      @context ||= JSON.parse(sqs_message.body)
    end

    def body
      @body ||= JSON.parse(context['Message'], quirks_mode: true)
    end

    def topic
      @topic ||= Topic.new(context['TopicArn'])
    end

    def id
      sqs_message.message_id
    end

    def receipt_handle
      sqs_message.receipt_handle
    end
  end
end
