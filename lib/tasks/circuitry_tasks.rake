require 'circuitry/provisioner'

namespace :circuitry do
  desc 'Create subscriber queues and subscribe queue to topics'
  task setup: :environment do
    logger = Logger.new(STDOUT)
    logger.level = Logger::INFO

    Circuitry::Provisioner.new(Circuitry.config, logger: logger).run
  end
end
