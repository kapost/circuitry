require 'circuitry/railtie' if defined?(Rails) && Rails::VERSION::MAJOR >= 3
require 'circuitry/config/publisher_settings'
require 'circuitry/config/subscriber_settings'
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
  class << self
    def subscriber_config
      @_sub_config ||= Config::SubscriberSettings.new
      yield @_sub_config if block_given?
      @_sub_config
    end

    def subscriber_config=(options)
      @_sub_config = Config::SubscriberSettings.new(options)
    end

    def publisher_config
      @_pub_config ||= Config::PublisherSettings.new
      yield @_pub_config if block_given?
      @_pub_config
    end

    def publisher_config=(options)
      @_pub_config = Config::PublisherSettings.new(options)
    end

    def publish(topic_name, object, options = {})
      Publisher.new(options).publish(topic_name, object)
    end

    def subscribe(options = {}, &block)
      Subscriber.new(options).subscribe(&block)
    end

    def flush
      Processors.constants.each do |const|
        Processors.const_get(const).flush
      end
    end
  end
end
