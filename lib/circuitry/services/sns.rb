require 'fog/aws'

module Circuitry
  module Services
    module SNS
      def sns
        @sns ||= Fog::AWS::SNS.new(Circuitry.config.aws_options)
      end
    end
  end
end
