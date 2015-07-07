require 'circuitry/version'
require 'circuitry/processor'
require 'circuitry/processors/batcher'
require 'circuitry/processors/threader'
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
    Processors::Batcher.flush
    Processors::Threader.flush
  end
end
