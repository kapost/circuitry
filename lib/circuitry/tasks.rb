namespace :circuitry do
  desc 'Create subscriber queues and subscribe queue to topics'
  task :setup do
    require 'logger'
    require 'circuitry/provisioning'

    logger = Logger.new(STDOUT)
    logger.level = Logger::INFO

    if Rake::Task.task_defined?(:environment)
      Rake::Task[:environment].invoke
    end

    Circuitry::Provisioning.provision(logger: logger)
  end
end
