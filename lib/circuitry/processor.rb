module Circuitry
  module Processor
    def process(&_block)
      raise NotImplementedError, "#{self} must implement class method `process`"
    end

    def flush
      raise NotImplementedError, "#{self} must implement class method `flush`"
    end

    protected

    def safely_process
      yield
    rescue => e
      logger.error("Error handling message: #{e}")
      error_handler.call(e) if error_handler
    end

    def pool
      @pool ||= []
    end

    private

    def logger
      Circuitry.subscriber_config.logger
    end

    def error_handler
      Circuitry.subscriber_config.error_handler
    end
  end
end
