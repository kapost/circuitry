require 'circuitry'
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
        subscribe_topics(queue, create_topics(:subscriber, subscriber_config.topic_names)) if queue
        create_topics(:publisher, publisher_config.topic_names)
      end

      private

      attr_accessor :logger

      def publisher_config
        Circuitry.publisher_config
      end

      def subscriber_config
        Circuitry.subscriber_config
      end

      def create_queue
        if subscriber_config.queue_name.nil?
          logger.info 'Skipping queue creation: queue_name is not configured'
          return nil
        end

        safe_aws('Create queue') do
          queue = QueueCreator.find_or_create(
            subscriber_config.queue_name,
            dead_letter_queue_name: subscriber_config.dead_letter_queue_name,
            max_receive_count: subscriber_config.max_receive_count,
            visibility_timeout: subscriber_config.visibility_timeout
          )
          logger.info "Created queue #{queue.url}"
          queue
        end
      end

      def create_topics(type, topics)
        safe_aws("Create #{type.to_s} topics") do
          topics.map do |topic_name|
            topic = TopicCreator.find_or_create(topic_name)
            logger.info "Created topic #{topic.name}"
            topic
          end
        end
      end

      def subscribe_topics(queue, topics)
        safe_aws('Subscribe to topics') do
          SubscriptionCreator.subscribe_all(queue, topics)
          plural_form = topics.size == 1 ? '' : 's'
          logger.info "Subscribed #{topics.size} topic#{plural_form} to #{queue.name}"
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
