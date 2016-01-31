require 'circuitry/services/sqs'
require 'circuitry/queue'

module Circuitry
  module Provisioning
    class QueueCreator
      include Services::SQS

      attr_reader :queue_name

      def self.find_or_create(queue_name, dead_letter_queue_name: nil, max_receive_count: 8 )
        creator = new(queue_name)
        result = creator.create_queue
        creator.create_dead_letter_queue(dead_letter_queue_name, max_receive_count) if dead_letter_queue_name
        result
      end

      def initialize(queue_name)
        @queue_name = queue_name
      end

      def create_queue
        @_queue ||= Queue.new(create_primary_queue_internal)
      end

      def create_dead_letter_queue(name, max_receive_count)
        @_dl_queue ||= Queue.new(create_dl_queue_internal(name, max_receive_count))
      end

      private

      def create_dl_queue_internal(name, max_receive_count)
        dl_url = sqs.create_queue(queue_name: name).queue_url
        dl_arn = sqs.get_queue_attributes(queue_url: dl_url, attribute_names: ['QueueArn']).attributes['QueueArn']

        sqs.set_queue_attributes(queue_url: create_queue.url, attributes: build_redrive_policy(dl_arn, max_receive_count))
        dl_url
      end

      def build_redrive_policy(deadletter_arn, max_receive_count)
        {
          'RedrivePolicy' => %({"maxReceiveCount":"#{max_receive_count}", "deadLetterTargetArn":"#{deadletter_arn}"})
        }
      end

      def create_primary_queue_internal
        attributes = { 'VisibilityTimeout' => (30 * 60).to_s }
        sqs.create_queue(queue_name: queue_name, attributes: attributes).queue_url
      end
    end
  end
end
