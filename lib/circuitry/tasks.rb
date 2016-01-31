namespace :circuitry do
  desc 'Create subscriber queues and subscribe queue to topics'
  task setup: :environment do
    require 'circuitry/provisioner'

    logger = Logger.new(STDOUT)
    logger.level = Logger::INFO

    Circuitry::Provisioning.provision_from_config(Circuitry.config, logger: logger)
  end
end
