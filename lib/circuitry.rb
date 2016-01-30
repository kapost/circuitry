require 'circuitry/railtie' if defined?(Rails) && Rails::VERSION::MAJOR >= 3
require 'circuitry/configuration'
require 'circuitry/locks/base'
require 'circuitry/locks/memcache'
require 'circuitry/locks/memory'
require 'circuitry/locks/noop'
require 'circuitry/locks/redis'
require 'circuitry/middleware/chain'
require 'circuitry/processor'
require 'circuitry/processors/batcher'
require 'circuitry/processors/forker'
require 'circuitry/processors/threader'
require 'circuitry/publisher'
require 'circuitry/subscriber'
require 'circuitry/version'

module Circuitry
  def self.config(&block)
    @config ||= Configuration.new
    block.call(@config) if block_given?
    @config
  end

  def self.publish(topic_name, object, options = {})
    Publisher.new(options).publish(topic_name, object)
  end

  def self.subscribe(options = {}, &block)
    Subscriber.new(options).subscribe(&block)
  end

  def self.flush
    Processors.constants.each do |const|
      Processors.const_get(const).flush
    end
  end
end
