module Circuitry
  class EventQueueCreator

    attr_reader :sqs, :sns, :queue_name


    def initialize(queue_name, sqs: Aws::SQS::Client.new, sns: Aws::SNS::Client.new)
      @queue_name = queue_name
      @sqs, @sns = sqs, sns
    end

    def verify_queue(topics)
      print "Testing for queue #{queue_name}... "
      if queue_exists?
        puts "exists."
        # TODO Validate the settings
      else
        create_primary_queue
        create_dead_letter_queue
        puts "created."
      end
      verify_subscriptions(topics)
    end

    def verify_subscriptions(topics)
      topics.each do |topic|
        full_name = [Circuitry.config.queue_prefix, topic].join("-")
        print "Subscribing to #{full_name}... "
        arn = topic_arn(full_name)
        sns.subscribe(topic_arn: arn, endpoint: queue_arn, protocol: 'sqs')
        puts "done."
      end
    end

    private

    attr_reader :queue_url

    def queue_exists?
      sqs.get_queue_url(queue_name: queue_name)
      # TODO: Make sure the VisibilityTimeout is correct
      true
    rescue Aws::SQS::Errors::NonExistentQueue => ex
      false
    end

    def create_primary_queue
      # The best way to discover the queue name is to try and create it. If it
      # exists, we'll get the same url back.
      queue_url
    end

    def queue_url
      attributes = { "VisibilityTimeout" => 30.minutes.to_i.to_s }
      @queue_url ||= sqs.create_queue(queue_name: queue_name, attributes: attributes).queue_url
    end

    def queue_arn
      @queue_arn ||= sqs.get_queue_attributes(queue_url: queue_url, attribute_names: ["QueueArn"]).attributes["QueueArn"]
    end

    def topic_arn(topic)
      # The best way to discover the topic name is to try and create it. If it
      # exists, we'll get the same topic back.
      topic = sns.create_topic(name: topic)
      topic.topic_arn
    end

    def topics
      @topics ||= sns.list_topics.topics
    end

    def create_dead_letter_queue
      dl_name = queue_name + "-failures"
      dl_url  = sqs.create_queue(queue_name: dl_name).queue_url
      dl_arn = sqs.get_queue_attributes(queue_url: dl_url, attribute_names: ["QueueArn"]).attributes["QueueArn"]

      redrive_attrs = {
        "RedrivePolicy" => %Q({"maxReceiveCount":"8", "deadLetterTargetArn":"#{dl_arn}"})
      }

      sqs.set_queue_attributes(queue_url: queue_url, attributes: redrive_attrs)
    end
  end

end
