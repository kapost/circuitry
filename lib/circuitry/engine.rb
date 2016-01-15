
module Circuitry
  class Engine < ::Rails::Engine
    config.before_initialize do
      config.circuitry = ActiveSupport::OrderedOptions.new
      config.circuitry.application_name = Rails.application.class.parent_name.underscore
    end

    config.after_initialize do
      config.circuitry.each do |key,val|
        Circuitry.config do |config|
          config.send(:"#{key}=", val)
        end
      end
    end
  end
end
