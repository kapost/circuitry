require 'concord/concerns/async'
require 'concord/services/sqs'
require 'concord/message'

module Concord
  class SubscribeError < StandardError; end

  class Subscriber
    include Concerns::Async
    include Services::SQS

    attr_reader :queue, :wait_time, :batch_size, :max_retries, :failure_queue

    DEFAULT_OPTIONS = {
        async: false,
        wait_time: 10,
        batch_size: 10,
    }.freeze

    CONNECTION_ERRORS = [
        Excon::Errors::Forbidden,
    ].freeze

    def initialize(queue, options = {})
      raise ArgumentError.new('queue cannot be nil') if queue.nil?

      options = DEFAULT_OPTIONS.merge(options)

      @queue = queue
      @async = !!options[:async]
      @wait_time = options[:wait_time]
      @batch_size = options[:batch_size]
    end

    def subscribe(&block)
      raise ArgumentError.new('block required') if block.nil?

      unless can_subscribe?
        logger.warn('Concord unable to subscribe: AWS configuration is not set.')
        return
      end

      process = -> do
        loop do
          begin
            receive_messages(&block)
          rescue *CONNECTION_ERRORS => e
            logger.error "Connection error to #{queue}: #{e}"
            raise SubscribeError.new(e)
          end
        end
      end

      if async?
        process_asynchronously(&process)
      else
        process.call
      end
    end

    def async?
      @async
    end

    private

    def receive_messages(&block)
      response = sqs.receive_message(queue, 'MaxNumberOfMessages' => batch_size, 'WaitTimeSeconds' => wait_time)
      messages = response.body['Message']
      return if messages.empty?

      messages.each do |message|
        process_message(message, &block)
      end
    end

    def process_message(message, &block)
      message = Message.new(message)

      unless message.nil?
        logger.info "Processing message #{message.id}"
        handle_message(message, &block)
        delete_message(message)
      end
    rescue => e
      logger.error "Error processing message #{message.id}: #{e}"
      error_handler.call(e) if error_handler
    end

    def handle_message(message, &block)
      block.call(message.body, message.topic.name)
    rescue => e
      logger.error("Error handling message #{message.id}: #{e}")
      raise e
    end

    def delete_message(message)
      logger.info("Removing message #{message.id} from queue")
      sqs.delete_message(queue, message.receipt_handle)
    end

    def logger
      Concord.config.logger
    end

    def error_handler
      Concord.config.error_handler
    end

    def can_subscribe?
      Concord.config.aws_options.values.all? do |value|
        !value.nil? && !value.empty?
      end
    end
  end
end
