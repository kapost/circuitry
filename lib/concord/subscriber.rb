require 'concord/services/sqs'
require 'concord/message'

module Concord
  class SubscribeError < StandardError; end

  class Subscriber
    include Services::SQS

    attr_reader :queue, :wait_time, :batch_size, :max_retries, :failure_queue

    DEFAULT_OPTIONS = {
        wait_time: 10,
        batch_size: 10,
    }.freeze

    def initialize(queue, options = {})
      raise ArgumentError('queue cannot be nil') if queue.nil?

      options = options.merge(DEFAULT_OPTIONS)

      @queue = queue
      @wait_time = options[:wait_time]
      @batch_size = options[:batch_size]
    end

    def subscribe(&block)
      loop do
        receive_messages(&block)
      end
    end

    private

    def receive_messages(&block)
      response = sqs.receive_message(queue, 'MaxNumberOfMessages' => batch_size, 'WaitTimeSeconds' => wait_time)
      messages = response.body['Message']
      return false if messages.empty?

      messages.each do |message|
        process_message(message, &block)
      end

      true
    rescue Excon::Errors::Forbidden => e
      logger.error "Access forbidden to #{queue}: #{e}"
      raise SubscribeError.new(e)
    end

    def process_message(message, &block)
      message = Message.new(message)

      unless message.nil?
        logger.info "Processing message #{message.id}"
        handle_message(message, &block)
        delete_message(message)
      end
    end

    def handle_message(message, &block)
      block.call(message.body)
    rescue => e
      logger.error("Error handling message #{message.id}: #{e}")
      requeue_message(message)
    end

    def requeue_message(message)
      logger.info "Requeuing message #{message.id}"
      sqs.send_message(queue, message.body)
    end

    def delete_message(message)
      logger.info("Removing message #{message.id} from queue")
      sqs.delete_message(queue, message.receipt_handle)
    end

    def logger
      Concord.config.logger
    end
  end
end
