require 'singleton'

module Circuitry
  class Batcher
    include Singleton

    def self.batch(*args)
      instance.batch(*args)
    end

    def self.flush(*args)
      instance.flush(*args)
    end

    def batch(&block)
      raise ArgumentError, 'no block given' unless block_given?
      batches << block
    end

    def flush
      batches.each do |batch|
        begin
          batch.call
        rescue => e
          logger.error("Error publishing message: #{e}")
          error_handler.call(e) if error_handler
        end
      end

      batches.clear
    end

    private

    def batches
      @batches ||= []
    end

    def logger
      Circuitry.config.logger
    end

    def error_handler
      Circuitry.config.error_handler
    end
  end
end
