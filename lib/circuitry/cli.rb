require 'circuitry/provisioning'
require 'thor'

module Circuitry
  class CLI < Thor
    class_option :verbose, aliases: :v, type: :boolean

    desc 'provision <queue> -t <topic> [<topic> ...]', 'Provision a queue subscribed to one or more topics'

    long_desc <<-END
      Creates an SQS queue with appropriate SNS access policy along with one or more SNS topics
      named <topic> that has an SQS subscription for each.

      When the queue already exists, its policy will be added or updated.

      When a topic already exists, it will be ignored.

      When a topic subscription already exists, it will be ignored.

      If no dead letter queue is specified, one will be created by default with the
      name <queue>-failures
    END

    option :topics, aliases: :t, type: :array, required: true
    option :access_key, aliases: :a, required: true
    option :secret_key, aliases: :s, required: true
    option :region, aliases: :r, required: true
    option :dead_letter_queue, aliases: :d
    option :visibility_timeout, aliases: :v
    option :max_retry_count, aliases: :t

    def provision(queue_name)
      with_custom_config(queue_name) do
        logger = Logger.new(STDOUT)
        logger.level = Logger::INFO if options['verbose']
        Circuitry::Provisioning.provision(logger: logger)
      end
    end

    private

    def say(*args)
      puts(*args) if options['verbose']
    end

    def with_custom_config(queue_name)
      assign_options_config(queue_name)
      yield
    end

    def assign_options_config(queue_name)
      [:access_key, :secret_key, :region].each do |key|
        Circuitry.subscriber_config.send(:"#{key}=", options.fetch(key.to_s))
        Circuitry.publisher_config.send(:"#{key}=", options.fetch(key.to_s))
      end

      Circuitry.subscriber_config.queue_name = queue_name
      Circuitry.subscriber_config.dead_letter_queue_name = options.fetch('dead_letter_queue', "#{queue_name}-failures")
      Circuitry.subscriber_config.topic_names = options['topics']
      Circuitry.publisher_config.topic_names = []
      Circuitry.subscriber_config.max_retry_count = options.fetch('max_retry_count', 8)
      Circuitry.subscriber_config.visibility_timeout = options.fetch('visibility_timeout', 30 * 60)
    end
  end
end
