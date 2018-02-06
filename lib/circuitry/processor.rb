module Circuitry
  class Processor
    attr_reader :config, :block

    def initialize(config, &block)
      raise ArgumentError, 'no block given' unless block_given?

      self.config = config
      self.block = block
    end

    def process
      raise NotImplementedError, "#{self} must implement instance method `process`"
    end

    def wait
      raise NotImplementedError, "#{self} must implement instance method `wait`"
    end

    protected

    def safely_process(&block)
      block.call
    rescue => e
      logger.error("Error handling message: #{e}")
      error_handler.call(e) if error_handler
    ensure
      on_exit.call if on_exit
    end

    private

    attr_writer :config, :block

    def logger
      config.logger
    end

    def error_handler
      config.error_handler
    end

    def on_exit
      config.on_async_exit
    end
  end
end
