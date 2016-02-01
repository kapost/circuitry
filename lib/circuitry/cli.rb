require 'circuitry/provisioning'
require 'thor'

module Circuitry
  class CLI < Thor
    class_option :verbose, aliases: :v, type: :boolean

    desc 'provision <queue> -t <topic> [<topic> ...]', <<-END
      Provision a queue subscribed to one or more topics
    END

    long_desc <<-END
      Creates an SQS queue with appropriate SNS access policy along with one or more SNS topics
      named <topic> that has an SQS subscription for each.

      When the queue already exists, its policy will be added or updated.

      When a topic already exists, it will be ignored.

      When a topic subscription already exists, it will be ignored.

      If no dead letter queue is specified, one will be created by default with the
      name <queue>-failures
    END

    option :topic_names, aliases: :t, type: :array, required: true
    option :access_key, aliases: :a, required: true
    option :secret_key, aliases: :s, required: true
    option :region, aliases: :r, required: true
    option :dead_letter_queue_name, aliases: :d
    option :visibility_timeout, aliases: :v, default: 30 * 60
    option :max_receive_count, aliases: :n, default: 8

    OPTIONS_KEYS_PUBLISHER_CONFIG = [:access_key, :secret_key, :region].freeze

    OPTIONS_KEYS_SUBSCRIBER_CONFIG = [:access_key, :secret_key, :region, :dead_letter_queue_name,
                                      :topic_names, :max_receive_count, :visibility_timeout].freeze

    def provision(queue_name)
      initialize_config(queue_name)

      logger = Logger.new(STDOUT)
      logger.level = Logger::INFO if options['verbose']
      Circuitry::Provisioning.provision(logger: logger)
    end

    private

    def say(*args)
      puts(*args) if options['verbose']
    end

    def initialize_config(queue_name)
      Circuitry.publisher_config.topic_names = []
      Circuitry.subscriber_config.queue_name = queue_name

      assign_options_config
    end

    def assign_options_config
      OPTIONS_KEYS_PUBLISHER_CONFIG.each do |key|
        Circuitry.publisher_config.send(:"#{key}=", options[key.to_s])
      end

      OPTIONS_KEYS_SUBSCRIBER_CONFIG.each do |key|
        Circuitry.subscriber_config.send(:"#{key}=", options[key.to_s])
      end
    end
  end
end
