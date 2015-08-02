require 'circuitry/queue'
require 'circuitry/topic'

module Circuitry
  class Provisioner
    class << self
      def create_topic(name)
        Topic.create(name)
      end

      def create_queue(name, options = {})
        queue = Queue.create(name, options)
        queue.policy = queue_policy(queue.arn)
        queue
      end

      def subscribe(topic, queue)
        topic.subscribe(queue)
      end

      private

      def queue_policy(queue_arn)
        {
            Id:            "#{queue_arn}/SQSDefaultPolicy",
            Version:       '2012-10-17',
            Statement: {
                Sid:       "#{queue_arn}+sqs:SendMessage",
                Action:    'SQS:SendMessage',
                Effect:    'Allow',
                Principal: { AWS: '*' },
                Resource:  queue_arn,
            }
        }
      end
    end
  end
end
