module Circuitry
  module Middleware
    class Entry
      attr_reader :klass, :args

      def initialize(klass, *args)
        self.klass = klass
        self.args  = args
      end

      def build
        klass.new(*args)
      end

      private

      attr_writer :klass, :args
    end
  end
end
