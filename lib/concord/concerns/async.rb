module Concord
  class NotSupportedError < StandardError; end

  module Concerns
    module Async
      def process_asynchronously(&block)
        raise NotSupportedError, 'Your platform does not support forking' unless platform_supports_async?

        pid = fork(&block)
        Process.detach(pid)
      end

      def platform_supports_async?
        Concord.platform_supports_async?
      end
    end
  end
end
