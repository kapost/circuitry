require 'rails'
require 'circuitry/config/file_loader'

module Circuitry
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'circuitry/tasks.rb'
    end

    initializer 'circuitry' do
      env = ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'

      %w[config/circuitry.yml.erb config/circuitry.yml].detect do |filename|
        Circuitry::Config::FileLoader.load(filename, env)
      end
    end
  end
end
