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
        Excon::Errors::Forbidden,
    ].freeze

    TEMPORARY_ERRORS = [
        Excon::Errors::InternalServerError,
        Excon::Errors::ServiceUnavailable,
        Excon::Errors::SocketError,
        Excon::Errors::Timeout,
    ].freeze

    def initialize(queue, options = {})
      raise ArgumentError.new('queue cannot be nil') if queue.nil?

      options = DEFAULT_OPTIONS.merge(options)

      self.queue = queue
      self.lock = options[:lock]
      self.async = options[:async]
      self.timeout = options[:timeout]
      self.wait_time = options[:wait_time]
      self.batch_size = options[:batch_size]
    end

    def subscribe(&block)
      raise ArgumentError.new('block required') if block.nil?

      unless can_subscribe?
        logger.warn('Circuitry unable to subscribe: AWS configuration is not set.')
        return
      end

      loop do
        begin
          receive_messages(&block)
        rescue *CONNECTION_ERRORS => e
          logger.error("Connection error to #{queue}: #{e}")
          raise SubscribeError.new(e)
        end
      end
    end

    def self.async_strategies
      super - [:batch]
    end

    def self.default_async_strategy
      Circuitry.config.subscribe_async_strategy
    end

    protected

    attr_writer :queue, :timeout, :wait_time, :batch_size

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

    def receive_messages(&block)
      response = nil

      begin
        response = sqs.receive_message(queue, 'MaxNumberOfMessages' => batch_size, 'WaitTimeSeconds' => wait_time)
      rescue *TEMPORARY_ERRORS => e
        logger.info("Temporary issue connecting to SQS: #{e.message}")
        return
      end

      messages = response.body['Message']
      return if messages.empty?

      messages.each do |message|
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

      handler = ->(exception, attempt_number, _total_delay) do
        logger.info("Temporary issue deleting message #{message.id} from SQS: #{exception.message} (attempt ##{attempt_number})")
      end

      with_retries(max_tries: 3, base_sleep_seconds: 0, max_sleep_seconds: 0, handler: handler, rescue: TEMPORARY_ERRORS) do
        sqs.delete_message(queue, message.receipt_handle)
      end
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
