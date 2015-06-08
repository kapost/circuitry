require 'logger'
require 'virtus'

module Concord
  class Configuration
    include Virtus::Model

    attribute :access_key, String
    attribute :secret_key, String
    attribute :region, String, default: 'us-east-1'
    attribute :logger, Logger, default: Logger.new(STDERR)
    attribute :error_handler

    def aws_options
      {
          aws_access_key_id:     access_key,
          aws_secret_access_key: secret_key,
          region:                region,
      }
    end
  end
end
