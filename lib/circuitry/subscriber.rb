require 'retries'
require 'timeout'
require 'circuitry/concerns/async'
require 'circuitry/services/sqs'
require 'circuitry/message'

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
        batch_size: 10,
    }.freeze

    CONNECTION_ERRORS = [
    ].freeze

    def initialize(queue, options = {})
      raise ArgumentError.new('queue cannot be nil') if queue.nil?

      options = DEFAULT_OPTIONS.merge(options)

      self.subscribed = false
      self.queue = queue
      self.lock = options[:lock]
      self.async = options[:async]
      self.timeout = options[:timeout]
      self.wait_time = options[:wait_time]
      self.batch_size = options[:batch_size]

      trap_signals
    end

    def subscribe(&block)
      raise ArgumentError.new('block required') if block.nil?
      raise SubscribeError.new('AWS configuration is not set') unless can_subscribe?

      logger.info("Subscribing to queue: #{queue}")

      self.subscribed = true
      poll(&block) while subscribed?

      logger.info("Unsubscribed from queue: #{queue}")
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
        else raise ArgumentError, "Invalid value `#{value}`, must be one of `true`, `false`, or instance of `#{Circuitry::Locks::Base}`"
      end

      @lock = value
    end

    private

    def trap_signals
      trap('SIGINT') do
        if subscribed?
          Thread.new { logger.info('Interrupt received, unsubscribing from queue...') }
          self.subscribed = false
        end
      end
    end

    def poll(&block)
      receive_messages(&block)
    rescue *CONNECTION_ERRORS => e
      logger.error("Connection error to #{queue}: #{e}")
      raise SubscribeError.new(e)
    end

    def receive_messages(&block)
      response = sqs.receive_message(
          queue_url:              queue,
          max_number_of_messages: batch_size,
          wait_time_seconds:      wait_time
      )

      response.messages.each do |message|
        process = -> do
          process_message(message, &block)
        end

        if async?
          process_asynchronously(&process)
        else
          process.call
        end
      end
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
      if lock.soft_lock(message.id)
        begin
          Timeout.timeout(timeout) do
            block.call(message.body, message.topic.name)
          end
        rescue => e
          lock.unlock(message.id)
          logger.error("Error handling message #{message.id}: #{e}")
          raise e
        end

        lock.hard_lock(message.id)
      else
        logger.info("Ignoring duplicate message #{message.id}")
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
  end
end
