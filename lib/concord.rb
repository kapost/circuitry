require 'concord/version'
require 'concord/configuration'
require 'concord/publisher'
require 'concord/subscriber'

module Concord
  def self.config(&block)
    @config ||= Configuration.new
    block.call(@config) if block_given?
    @config
  end

  def self.publish(topic_name, object, options = {})
    Publisher.new(topic_name, object, options).publish
  end

  def self.subscribe(queue, options = {}, &block)
    Subscriber.new(queue, options).subscribe(&block)
  end
end
