namespace :circuitry do
  desc 'Create subscriber queues and subscribe queue to topics'
  task :setup do
    require 'logger'
    require 'circuitry/provisioning'

    logger = Logger.new(STDOUT)
    logger.level = Logger::INFO

    Circuitry::Provisioning.provision(logger: logger)
  end

  if Rake::Task.task_defined?(:environment)
    task setup: :environment
  end
end
