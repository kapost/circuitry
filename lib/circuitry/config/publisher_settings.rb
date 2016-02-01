require 'virtus'
require 'circuitry/config/shared_settings'

module Circuitry
  module Config
    class PublisherSettings
      include Virtus::Model
      include SharedSettings
    end
  end
end
