require 'aws-sdk'

module Circuitry
  module Services
    module SNS
      def sns
        @sns ||= Aws::SNS::Client.new(Circuitry.config.aws_options)
      end
    end
  end
end
