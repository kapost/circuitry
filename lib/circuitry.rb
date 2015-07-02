require 'circuitry/version'
require 'circuitry/batcher'
require 'circuitry/configuration'
require 'circuitry/publisher'
require 'circuitry/subscriber'

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
    Batcher.flush
  end
end
