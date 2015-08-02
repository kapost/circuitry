require 'thor'

module Circuitry
  class CLI < Thor
    desc 'provision QUEUE TOPIC [TOPIC ...]', 'Provision a queue subscribed to one or more topics'
    def provision(queue, topic, *topics)
      topics.unshift(topic)
      puts "Creating queue '#{queue}' with topics #{topics.map { |topic| "'#{topic}'" }.join(', ')}"

      Circuitry.provision(queue, *topics)
    end
  end
end
