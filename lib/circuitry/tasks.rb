namespace :circuitry do
  desc 'Create subscriber queues and subscribe queue to topics'
  task setup: :environment do
    require 'circuitry/provisioning'

    logger = Logger.new(STDOUT)
    logger.level = Logger::INFO

    Circuitry::Provisioning.provision(logger: logger)
  end
end
