require 'yaml'
require 'erb'
require 'fileutils'

module Circuitry
  module Config
    module FileLoader
      def self.load(cfile, environment = 'development')
        return nil unless File.exist?(cfile)

        opts = {}
        opts = YAML.load(ERB.new(IO.read(cfile)).result) || opts
        opts = opts.merge(opts.delete(environment) || {})

        publisher_opts = opts.merge(opts.delete('publisher') || {})
        subscriber_opts = opts.merge(opts.delete('subscriber') || {})

        Circuitry.subscriber_config = subscriber_opts
        Circuitry.publisher_config = publisher_opts
        true
      end
    end
  end
end
