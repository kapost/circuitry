module Circuitry
  module Pool
    class << self
      def <<(processor)
        raise ArgumentError, 'processor must be a Circuitry::Processor' unless processor.is_a?(Circuitry::Processor)
        pool << processor
      end

      def flush
        while (processor = pool.shift)
          processor.wait
        end
      end

      def size
        pool.size
      end

      def empty?
        pool.empty?
      end

      def any?
        pool.any?
      end

      private

      def pool
        @pool ||= []
      end
    end
  end
end
