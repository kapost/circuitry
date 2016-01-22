require "circuitry/event_queue_creator"

namespace :circuitry do
  desc "Create listen queue and subscribe to topics"
  task :setup => :environment do
    creator = Circuitry::EventQueueCreator.new(Circuitry.config.subscriber_queue_name)
    creator.verify_queue(Circuitry.config.subscribed_topics)
  end

end
