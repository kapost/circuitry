require 'circuitry/provisioning/provisioner'

module Circuitry
  module Provisioning
    def self.provision(logger: Logger.new(STDOUT))
      Provisioning::Provisioner.new(logger).run
    end
  end
end
