require 'circuitry/provisioning/provisioner'

module Circuitry
  module Provisioning
    def self.provision(config, logger: Logger.new(STDOUT))
      Provisioning::Provisioner.new(config, logger).run
    end
  end
end
