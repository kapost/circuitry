require 'rails'

module Circuitry
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'circuitry/tasks.rb'
    end
  end
end
