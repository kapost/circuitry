require 'circuitry/provisioning/queue_creator'
require 'circuitry/provisioning/topic_creator'
require 'circuitry/provisioning/subscription_creator'

module Circuitry
  module Provisioning
    class Provisioner
      def initialize(config, logger)
        self.config = config
        self.logger = logger
      end

      def run
        queue = create_queue
        return unless queue

        create_topics(:publisher, config.publisher_topic_names)
        subscribe_topics(queue, create_topics(:subscriber, config.subscriber_topic_names))
      end

      private

      attr_accessor :config
      attr_accessor :logger

      def create_queue
        safe_aws('Create Queue') do
          queue = QueueCreator.find_or_create(
            config.subscriber_queue_name,
            dead_letter_queue_name: config.subscriber_dead_letter_queue_name
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
