require 'fog/aws'

module Concord
  module Services
    module SNS
      def sns
        @sns ||= Fog::AWS::SNS.new(Concord.config.aws_options)
      end
    end
  end
end
