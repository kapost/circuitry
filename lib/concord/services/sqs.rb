require 'fog/aws'

module Concord
  module Services
    module SQS
      def sqs
        @sqs ||= Fog::AWS::SQS.new(Concord.config.aws_options)
      end
    end
  end
end
