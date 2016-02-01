require 'aws-sdk'

module Circuitry
  module Services
    module SQS
      def sqs
        @sqs ||= Aws::SQS::Client.new(Circuitry.subscriber_config.aws_options)
      end
    end
  end
end
