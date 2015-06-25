require 'fog/aws'

module Circuitry
  module Services
    module SQS
      def sqs
        @sqs ||= Fog::AWS::SQS.new(Circuitry.config.aws_options)
      end
    end
  end
end
