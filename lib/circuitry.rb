require 'circuitry/configuration'
require 'circuitry/locks/base'
require 'circuitry/locks/memcache'
require 'circuitry/locks/memory'
require 'circuitry/locks/noop'
require 'circuitry/locks/redis'
require 'circuitry/processor'
require 'circuitry/processors/batcher'
require 'circuitry/processors/forker'
require 'circuitry/processors/threader'
require 'circuitry/provisioner'
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

  def self.subscribe(queue, options = {}, &block)
    Subscriber.new(queue, options).subscribe(&block)
  end

  def self.flush
    Processors.constants.each do |const|
      Processors.const_get(const).flush
    end
  end

  def self.provision(queue_name, *topic_names)
    queue = Provisioner.create_queue(queue_name)

    topic_names.each do |topic_name|
      topic = Provisioner.create_topic(topic_name)
      Provisioner.subscribe(topic, queue)
    end
  end
end
