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

    option :topics, aliases: :t, type: :array, required: :true
    option :access_key, aliases: :a
    option :secret_key, aliases: :s
    option :dead_letter_queue, aliases: :d
    option :region, aliases: :r

    def provision(queue_name)
      with_custom_config(queue_name) do |config|
        logger = Logger.new(STDOUT)
        logger.level = Logger::INFO if options['verbose']
        Circuitry::Provisioning.provision_from_config(config, logger: logger)
      end
    end

    private

    def say(*args)
      puts(*args) if options['verbose']
    end

    def with_custom_config(queue_name, &block)
      original_values = {}
      %i[access_key secret_key region subscriber_queue_name subscriber_dead_letter_queue_name subscriber_topic_names].each do |sym|
        original_values[sym] = Circuitry.config.send(sym)
      end

      assign_options_config(queue_name, original_values)

      block.call(Circuitry.config)
    ensure
      restore_config(original_values)
    end

    def assign_options_config(queue_name, original_values)
      Circuitry.config.access_key = options.fetch('access_key', original_values[:access_key])
      Circuitry.config.secret_key = options.fetch('secret_key', original_values[:secret_key])
      Circuitry.config.region = options.fetch('region', original_values[:region])
      Circuitry.config.subscriber_queue_name = queue_name
      Circuitry.config.subscriber_dead_letter_queue_name = options.fetch('dead_letter_queue', "#{queue_name}-failures")
      Circuitry.config.subscriber_topic_names = options['topics']
    end

    def restore_config(original_values)
      original_values.keys.each { |key| Circuitry.config.send(:"#{key}=", original_values[key]) }
    end
  end
end
