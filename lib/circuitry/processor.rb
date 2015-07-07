module Circuitry
  module Processor
    def process(&block)
      begin
        block.call
      rescue => e
        logger.error("Error publishing message: #{e}")
        error_handler.call(e) if error_handler
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
end
