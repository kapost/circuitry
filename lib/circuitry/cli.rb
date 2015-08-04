require 'circuitry/queue'
require 'circuitry/topic'
require 'thor'

module Circuitry
  class CLI < Thor
    class_option :verbose, aliases: :v, type: :boolean

    desc 'provision <queue> -t <topic> [<topic> ...]', 'Provision a queue subscribed to one or more topics'

    long_desc <<-END
      Creates an SQS queue named <queue> with appropriate SNS access policy along
      with one or more SNS topics named <topic> that has an SQS subscription for
      each.

      When the queue already exists, its policy will be added or updated.

      When a topic already exists, it will be ignored.

      When a topic subscription already exists, it will be ignored.

      With --failure-queue <queue> option, the redrive policy will be enabled,
      and the maximum number of failures for message handling will transfer the
      queued messages into the failure queue.

      With --retries <n> option, the redrive policy will have a max receive count
      of <n>.
    END

    option :topics, aliases: :t, type: :array, required: :true
    option :failure_queue, aliases: :f
    option :retries, aliases: :n, type: :numeric, default: 20
    option :access_key, aliases: :a
    option :secret_key, aliases: :s
    option :region, aliases: :r

    def provision(queue_name)
      with_custom_config do
        # create failure queue
        failure_queue = create_failure_queue(options[:failure_queue])

        # create main queue
        queue = create_queue(queue_name, failure_queue, retries: options[:retries])

        # create topics & subscriptions
        options[:topics].each do |topic_name|
          create_subscribed_topic(topic_name, queue)
        end
      end
    end

    private

    def say(*args)
      puts(*args) if options[:verbose]
    end

    def with_custom_config(&block)
      original_access_key = Circuitry.config.access_key
      original_secret_key = Circuitry.config.access_key
      original_region = Circuitry.config.region

      Circuitry.config.access_key = options.fetch(:access_key, original_access_key)
      Circuitry.config.secret_key = options.fetch(:secret_key, original_secret_key)
      Circuitry.config.region = options.fetch(:region, original_region)

      block.call
    ensure
      Circuitry.config.access_key = original_access_key
      Circuitry.config.access_key = original_secret_key
      Circuitry.config.region = original_region
    end

    def create_failure_queue(name)
      queue = nil

      if name
        queue = Queue.create(options[:failure_queue])
        say "Created failure queue #{queue.name} with ARN #{queue.arn}"
      end

      queue
    end

    def create_queue(name, failure_queue, retries: 20)
      queue = Queue.create(name)
      queue.policy = queue_policy(queue)
      queue.redrive_policy = redrive_policy(failure_queue, retries) if failure_queue
      say "Created queue #{queue.name} with ARN #{queue.arn}"
      queue
    end

    def create_subscribed_topic(name, queue)
      topic = Topic.create(name)
      say "Created topic #{topic.name} with ARN #{topic.arn}"

      topic.subscribe(queue)
      say "Subscribed topic #{topic.name} to queue #{queue.name}"

      topic
    end

    def queue_policy(queue)
      {
          Id:            "#{queue.arn}/SQSDefaultPolicy",
          Version:       '2012-10-17',
          Statement: {
              Sid:       "#{queue.arn}+sqs:SendMessage",
              Action:    'SQS:SendMessage',
              Effect:    'Allow',
              Principal: { AWS: '*' },
              Resource:  queue.arn,
          }
      }
    end

    def redrive_policy(dead_letter_queue, max_receive_count = 20)
      {
          deadLetterTargetArn: dead_letter_queue.arn,
          maxReceiveCount: max_receive_count,
      }
    end
  end
end
