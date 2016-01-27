require 'circuitry/queue_creator'
require 'circuitry/topic_creator'
require 'circuitry/subscription_creator'

module Circuitry
  class Provisioner
    attr_reader :log
    attr_reader :config

    def initialize(config, logger: Logger.new(STDOUT))
      @config = config
      @log = logger
    end

    def run
      queue = create_queue
      topics = create_topics if queue
      subscribe_topics(queue, topics) if queue && topics
    end

    private

    def create_queue
      safe_aws('Create Queue') do
        queue = Circuitry::QueueCreator.find_or_create(
          config.subscriber_queue_name,
          dead_letter_queue_name: config.subscriber_dead_letter_queue_name
        )
        log.info "Created queue #{queue.url}"
        queue
      end
    end

    def create_topics
      safe_aws('Create Topics') do
        config.publisher_topic_names.map do |topic_name|
          topic = Circuitry::TopicCreator.find_or_create(topic_name)
          log.info "Created topic #{topic.name}"
          topic
        end
      end
    end

    def subscribe_topics(queue, topics)
      safe_aws('Subscribe Topics') do
        Circuitry::SubscriptionCreator.subscribe_all(queue, topics)
        log.info "Subscribed all topics to #{queue.name}"
        true
      end
    end

    def safe_aws(desc)
      yield
    rescue Aws::SQS::Errors::AccessDenied
      log.fatal("#{desc}: Access denied. Check your configured credentials.")
      nil
    end
  end
end
