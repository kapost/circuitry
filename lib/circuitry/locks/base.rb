module Circuitry
  module Locks
    module Base
      DEFAULT_SOFT_TIMEOUT = (15 * 60).freeze       # 15 minutes
      DEFAULT_HARD_TIMEOUT = (24 * 60 * 60).freeze  # 24 hours

      attr_reader :soft_timeout, :hard_timeout

      def initialize(options = {})
        self.soft_timeout = options.fetch(:soft_timeout, DEFAULT_SOFT_TIMEOUT)
        self.hard_timeout = options.fetch(:hard_timeout, DEFAULT_HARD_TIMEOUT)
      end

      def soft_lock(id)
        lock(soft_lock_key(id), soft_timeout)
      end

      def soft_release(id)
        release(soft_lock_key(id))
      end

      def hard_lock(id)
        lock(hard_lock_key(id), hard_timeout)
      end

      def hard_release(id)
        release(hard_lock_key(id))
      end

      def reap
        raise NotImplementedError
      end

      protected

      def lock(key, timeout)
        raise NotImplementedError
      end

      def release(key)
        raise NotImplementedError
      end

      private

      attr_writer :soft_timeout, :hard_timeout

      def soft_lock_key(id)
        "soft-#{id}"
      end

      def hard_lock_key(id)
        "hard-#{id}"
      end
    end
  end
end
