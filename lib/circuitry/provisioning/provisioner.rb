require 'circuitry/provisioning/queue_creator'
require 'circuitry/provisioning/topic_creator'
require 'circuitry/provisioning/subscription_creator'

module Circuitry
  module Provisioning
    class Provisioner
      def initialize(logger)
        self.logger = logger
      end

      def run
        queue = create_queue
        return unless queue

        create_topics(:publisher, Circuitry.publisher_config.topic_names)
        subscribe_topics(queue, create_topics(:subscriber, Circuitry.subscriber_config.topic_names))
      end

      private

      attr_accessor :logger

      def create_queue
        safe_aws('Create Queue') do
          queue = QueueCreator.find_or_create(
            Circuitry.subscriber_config.queue_name,
            dead_letter_queue_name: Circuitry.subscriber_config.dead_letter_queue_name,
            max_receive_count: Circuitry.subscriber_config.max_retry_count
          )
          logger.info "Created queue #{queue.url}"
          queue
        end
      end

      def create_topics(type, topics)
        safe_aws("Create #{type.to_s.capitalize} Topics") do
          topics.map do |topic_name|
            topic = TopicCreator.find_or_create(topic_name)
            logger.info "Created topic #{topic.name}"
            topic
          end
        end
      end

      def subscribe_topics(queue, topics)
        safe_aws('Subscribe Topics') do
          SubscriptionCreator.subscribe_all(queue, topics)
          logger.info "Subscribed all topics to #{queue.name}"
          true
        end
      end

      def safe_aws(desc)
        yield
      rescue Aws::SQS::Errors::AccessDenied
        logger.fatal("#{desc}: Access denied. Check your configured credentials.")
        nil
      end
    end
  end
end
