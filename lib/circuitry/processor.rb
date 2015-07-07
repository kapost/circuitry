module Circuitry
  module Processor
    def process
      raise NotImplementedError, "#{self.to_s} must implement class method `process`"
    end

    def flush
      raise NotImplementedError, "#{self.to_s} must implement class method `flush`"
    end

    protected

    def process_entry(&block)
      begin
        block.call
      rescue => e
        logger.error("Error publishing message: #{e}")
        error_handler.call(e) if error_handler
      end
    end

    def pool
      @pool ||= []
    end

    private

    def logger
      Circuitry.config.logger
    end

    def error_handler
      Circuitry.config.error_handler
    end
  end
end
