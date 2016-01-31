require 'retries'
require 'timeout'
require 'circuitry/concerns/async'
require 'circuitry/services/sqs'
require 'circuitry/message'
require 'circuitry/queue'

module Circuitry
  class SubscribeError < StandardError; end

  class Subscriber
    include Concerns::Async
    include Services::SQS

    attr_reader :queue, :timeout, :wait_time, :batch_size, :lock

    DEFAULT_OPTIONS = {
      lock: true,
      async: false,
      timeout: 15,
      wait_time: 10,
      batch_size: 10
    }.freeze

    CONNECTION_ERRORS = [
      Aws::SQS::Errors::ServiceError
    ].freeze

    def initialize(options = {})
      options = DEFAULT_OPTIONS.merge(options)

      self.subscribed = false

      self.queue = Queue.find(Circuitry.config.subscriber_queue_name).url
      %i[lock async timeout wait_time batch_size].each do |sym|
        send(:"#{sym}=", options[sym])
      end

      trap_signals
    end

    def subscribe(&block)
      raise ArgumentError, 'block required' if block.nil?
      raise SubscribeError, 'AWS configuration is not set' unless can_subscribe?

      logger.info("Subscribing to queue: #{queue}")

      self.subscribed = true
      poll(&block)
      self.subscribed = false

      logger.info("Unsubscribed from queue: #{queue}")
    rescue *CONNECTION_ERRORS => e
      logger.error("Connection error to queue: #{queue}: #{e}")
      raise SubscribeError, e.message
    end

    def subscribed?
      subscribed
    end

    def self.async_strategies
      super - [:batch]
    end

    def self.default_async_strategy
      Circuitry.config.subscribe_async_strategy
    end

    protected

    attr_writer :queue, :timeout, :wait_time, :batch_size
    attr_accessor :subscribed

    def lock=(value)
      value = case value
              when true then Circuitry.config.lock_strategy
              when false then Circuitry::Locks::NOOP.new
              when Circuitry::Locks::Base then value
              else raise ArgumentError, lock_value_error(value)
              end

      @lock = value
    end

    private

    def lock_value_error(value)
      opts = Circuitry::Locks::Base
      "Invalid value `#{value}`, must be one of `true`, `false`, or instance of `#{opts}`"
    end

    def trap_signals
      trap('SIGINT') do
        if subscribed?
          Thread.new { logger.info('Interrupt received, unsubscribing from queue...') }
          self.subscribed = false
        end
      end
    end

    def poll(&block)
      poller = Aws::SQS::QueuePoller.new(queue, client: sqs)

      poller.before_request do |_stats|
        throw :stop_polling unless subscribed?
      end

      poller.poll(max_number_of_messages: batch_size, wait_time_seconds: wait_time, skip_delete: true) do |messages|
        process_messages(Array(messages), &block)
      end
    end

    def process_messages(messages, &block)
      if async?
        process_messages_asynchronously(messages, &block)
      else
        process_messages_synchronously(messages, &block)
      end
    end

    def process_messages_asynchronously(messages, &block)
      messages.each { |message| process_asynchronously { process_message(message, &block) } }
    end

    def process_messages_synchronously(messages, &block)
      messages.each { |message| process_message(message, &block) }
    end

    def process_message(message, &block)
      message = Message.new(message)

      logger.info("Processing message #{message.id}")
      handle_message(message, &block)
      delete_message(message)
    rescue => e
      logger.error("Error processing message #{message.id}: #{e}")
      error_handler.call(e) if error_handler
    end

    def handle_message(message, &block)
      handled = try_with_lock(message.id) do
        middleware.invoke(message.topic.name, message.body) do
          handle_message_with_timeout(message, &block)
        end
      end

      logger.info("Ignoring duplicate message #{message.id}") unless handled
    end

    # TODO: Don't use ruby timeout.
    # http://www.mikeperham.com/2015/05/08/timeout-rubys-most-dangerous-api/
    def handle_message_with_timeout(message, &block)
      Timeout.timeout(timeout) do
        block.call(message.body, message.topic.name)
      end
    rescue => e
      logger.error("Error handling message #{message.id}: #{e}")
      raise e
    end

    def try_with_lock(handle)
      if lock.soft_lock(handle)
        begin
          yield
        rescue => e
          lock.unlock(handle)
          raise e
        end

        lock.hard_lock(handle)
        true
      else
        false
      end
    end

    def delete_message(message)
      logger.info("Removing message #{message.id} from queue")
      sqs.delete_message(queue_url: queue, receipt_handle: message.receipt_handle)
    end

    def logger
      Circuitry.config.logger
    end

    def error_handler
      Circuitry.config.error_handler
    end

    def can_subscribe?
      Circuitry.config.aws_options.values.all? do |value|
        !value.nil? && !value.empty?
      end
    end

    def middleware
      Circuitry.config.subscriber_middleware
    end
  end
end
