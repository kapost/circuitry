require 'circuitry/provisioning/queue_creator'
require 'circuitry/provisioning/topic_creator'
require 'circuitry/provisioning/subscription_creator'

module Circuitry
  module Provisioning
    class << self
      def provision_from_config(config, logger: Logger.new(STDOUT))
        queue = create_queue(
          config.subscriber_queue_name,
          config.subscriber_dead_letter_queue_name,
          logger
        )
        return unless queue

        create_topics(:publisher, config.publisher_topic_names, logger)
        subscribe_topics(queue, create_topics(:subscriber, config.subscriber_topic_names, logger), logger)
      end

      private

      def create_queue(queue_name, dead_letter_queue_name, logger)
        safe_aws(logger, 'Create Queue') do
          queue = QueueCreator.find_or_create(
            queue_name,
            dead_letter_queue_name: dead_letter_queue_name
          )
          logger.info "Created queue #{queue.url}"
          queue
        end
      end

      def create_topics(type, topics, logger)
        safe_aws(logger, "Create #{type.to_s.capitalize} Topics") do
          topics.map do |topic_name|
            topic = TopicCreator.find_or_create(topic_name)
            logger.info "Created topic #{topic.name}"
            topic
          end
        end
      end

      def subscribe_topics(queue, topics, logger)
        safe_aws(logger, 'Subscribe Topics') do
          SubscriptionCreator.subscribe_all(queue, topics)
          logger.info "Subscribed all topics to #{queue.name}"
          true
        end
      end

      def safe_aws(logger, desc)
        yield
      rescue Aws::SQS::Errors::AccessDenied
        logger.fatal("#{desc}: Access denied. Check your configured credentials.")
        nil
      end
    end
  end
end
