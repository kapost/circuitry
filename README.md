# Circuitry

Notification pub/sub and message queue processing using Amazon
[SNS](http://aws.amazon.com/sns/) & [SQS](http://aws.amazon.com/sqs/).

[![Code Climate](https://codeclimate.com/repos/55720235e30ba0148f003033/badges/697cd6b997cc25e808f3/gpa.svg)](https://codeclimate.com/repos/55720235e30ba0148f003033/feed)
[![Test Coverage](https://codeclimate.com/repos/55720235e30ba0148f003033/badges/697cd6b997cc25e808f3/coverage.svg)](https://codeclimate.com/repos/55720235e30ba0148f003033/coverage)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'circuitry'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install circuitry

## Usage

Circuitry is configured via its configuration object.

```ruby
Circuitry.config do |c|
  c.access_key = 'YOUR_AWS_ACCESS_KEY'
  c.secret_key = 'YOUR_AWS_SECRET_KEY'
  c.region = 'us-east-1'
  c.logger = Rails.logger
  c.error_handler = proc do |error|
    HoneyBadger.notify(error)
    HoneyBadger.flush
  end
  c.publish_async_strategy = :batch
  c.subscribe_async_strategy = :thread
end
```

Available configuration options include:

* `access_key`: The AWS access key ID that has access to SNS publishing and/or
  SQS subscribing.  *(required)*
* `secret_key`: The AWS secret access key that has access to SNS publishing
  and/or SQS subscribing.  *(required)*
* `region`: The AWS region that your SNS and/or SQS account lives in.
  *(optional, default: "us-east-1")*
* `logger`: The logger to use for informational output, warnings, and error
  messages.  *(optional, default: `Logger.new(STDOUT)`)*
* `error_handler`: An object that responds to `call` with two arguments: the
  deserialized message contents and the topic name used when publishing to SNS.
  *(optional, default: `nil`)*
* `publish_async_strategy`: One of `:fork`, `:thread`, or `:batch` that
  determines how asynchronous publish requests are processed.  *(optional,
  default: `:fork`)*
  * `:fork`: Forks a detached child process that immediately sends the request.
  * `:thread`: Creates a new thread that immediately sends the request.  Because
    threads are not guaranteed to complete when the process exits, completion can
    be ensured by calling `Circuitry.flush`.
  * `:batch`: Stores the request in memory to be submitted later.  Batched
    requests must be manually sent by calling `Circuitry.flush`.
* `subscribe_async_strategy`: One of `:fork` or `:thread` that determines how
  asynchronous subscribe requests are processed.  *(optional, default: `:fork`)*
  * `:fork`: Forks a detached child process that immediately begins querying the
    queue.
  * `:thread`: Creates a new thread that immediately sends begins querying the
    queue.

### Publishing

Publishing is done via the `Circuitry.publish` method.  It accepts a topic name
that represents the SNS topic along with any non-nil object, representing the
data to be serialized.  Whatever object is called will have its `to_json` method
called for serialization.

```ruby
obj = { foo: 'foo', bar: 'bar' }
Circuitry.publish('any-topic-name', obj)
```

The `publish` method also accepts options that impact instantiation of the
`Publisher` object, which currently includes the following options.

* `:async` - Whether or not publishing should occur in the background.  Accepts
  one of `:fork`, `:thread`, `:batch`, `true`, or `false`.  Passing `true` uses
  the `publish_async_strategy` value from the gem configuration.  Please refer to
  the [Asynchronous Support](#asynchronous-support) section for more details
  regarding this option.  *(default: `false`)*
* `:timeout` - The maximum amount of time in seconds that publishing a message
  will be attempted before giving up.  If the timeout is exceeded, an exception
  will raised to be handled by your application or `error_handler`. *(default:
  15)*

```ruby
obj = { foo: 'foo', bar: 'bar' }
Circuitry.publish('my-topic-name', obj, async: true, timeout: 20)
```

Alternatively, if your options hash will remain unchanged, you can build a single
`Publisher` object to use for all publishing.

```ruby
options = { ... }
publisher = Circuitry::Publisher.new(options)
publisher.publish('my-topic-name', obj)
```

### Subscribing

Subscribing is done via the `Circuitry.subscribe` method.  It accepts an SQS queue
URL and takes a block for processing each message.  This method **indefinitely
blocks**, processing messages as they are enqueued.

```ruby
Circuitry.subscribe('https://sqs.REGION.amazonaws.com/ACCOUNT-ID/QUEUE-NAME') do |message, topic_name|
  puts "Received #{topic_name} message: #{message.inspect}"
end
```

The `subscribe` method also accepts options that impact instantiation of the
`Subscriber` object, which currently includes the following options.

* `:async` - Whether or not subscribing should occur in the background.  Accepts
  one of `:fork`, `:thread`, `true`, or `false`.  Passing `true` uses the
  `subscribe_async_strategy` value from the gem configuration.  Passing an
  asynchronous value will cause messages to be handled concurrently, meaning
  that queued messages *might not be processed in the order they're received*.
  Please refer to the [Asynchronous Support](#asynchronous-support) section for
  more details regarding this option.  *(default: `false`)*
* `:timeout` - The maximum amount of time in seconds that processing a message
  will be attempted before giving up.  If the timeout is exceeded, an exception
  will raised to be handled by your application or `error_handler`.  *(default:
  15)*
* `:wait_time` - The number of seconds to wait for messages while connected to
  SQS.  Anything above 0 results in long-polling, while 0 results in
  short-polling.  *(default: 10)*
* `:batch_size` - The number of messages to retrieve in a single SQS request.
  *(default: 10)*
* `:lock_strategy` - The store used to ensure that no duplicate messages are
  processed.  Please refer to the [Lock Strategies](#lock-strategies) section for
  more details regarding this option.  *(default: `Circuitry::Locks::Memory.new`)*

```ruby
options = {
  async: true,
  timeout: 20,
  wait_time: 60,
  batch_size: 20,
  lock_strategy: Circuitry::Locks::Redis.new(url: 'redis://...')
}

Circuitry.subscribe('https://...', options) do |message, topic_name|
  # ...
end
```

Alternatively, if your options hash will remain unchanged, you can build a single
`Subscriber` object to use for all subscribing.

```ruby
options = { ... }
subscriber = Circuitry::Subscriber.new(options)
subscriber.subscribe('https://...') do |message, topic_name|
  # ...
end
```

### Asynchronous Support

Publishing supports three asynchronous strategies (forking, threading, and
batching) while subscribing supports two (forking and threading).

#### Forking

When forking a child process, that child is detached so that your application
does not need to worry about waiting for the process to finish.  Forked requests
begin processing immediately and do not have any overhead in terms of waiting for
them to complete.

There are two important notes regarding forking in general as it relates to
asynchronous support:

1. Forking is not supported on all platforms (e.g.: Windows and NetBSD 4),
   requiring that your implementation use synchronous requests or an alternative
   asynchronous strategy in such circumstances.

2. Forking results in resources being copied from the parent process to the child
   process.  In order to prevent database connection errors and the like, you
   should properly handle closing and reopening resources before and after
   forking, respectively.  For example, if you are using Rails with Unicorn, you
   may need to add the following code to your `unicorn.rb` configuration:

        before_fork do |server, worker|
          if defined?(ActiveRecord::Base)
            ActiveRecord::Base.connection.disconnect!
          end
        end

        after_fork do |server, worker|
          if defined?(ActiveRecord::Base)
            ActiveRecord::Base.establish_connection(
              Rails.application.config.database_configuration[Rails.env]
            )
          end
        end

   Refer to your adapter's documentation to determine how resources are handled
   with regards to forking.

#### Threading

Threaded publish and subscribe requests begin processing immediately.  Unlike
forking, it's up to you to ensure that all threads complete before your
application exits.  This can be done by calling `Circuitry.flush`.

#### Batching

Batched publish and subscribe requests are queued in memory and do not begin
processing until you explicit flush them.  This can be done by calling
`Circuitry.flush`.

### Lock Strategies

The [Amazon SQS FAQ](http://aws.amazon.com/sqs/faqs/) includes the following
important point:

> Amazon SQS is engineered to provide “at least once” delivery of all messages in
> its queues. Although most of the time each message will be delivered to your
> application exactly once, you should design your system so that processing a
> message more than once does not create any errors or inconsistencies.

Given this, it's up to the user to ensure messages are not processed multiple
times in the off chance that Amazon does not recognize that a message has been
processed.

The circuitry gem handles this by caching SQS message IDs: first via a "soft
lock" that denotes the message is about to be processed, then via a "hard lock"
that denotes the message has finished processing.  The soft lock has a default
timeout of 15 minutes (a seemingly sane amount of time during which processing
most queue messages should certainly be able to complete), while the hard lock
has a default timeout of 24 hours (based upon [a suggestion by an AWS employee]
(https://forums.aws.amazon.com/thread.jspa?threadID=140782#507605)).

#### Memory

If not specified in your circuitry configuration, the memory store will be used
by default.  This lock strategy should be avoided if running multiple subscriber
processes.

```ruby
Circuitry::Memory::Lock.new
```

#### Redis

```ruby
# pass in redis client
client = Redis.new(url: 'redis://localhost:6379')
Circuitry::Memory::Redis.new(client: client)

# pass in redis options
Circuitry::Memory::Redis.new(url: 'redis://localhost:6379')
```

#### Memcache

```ruby
# pass in dalli client
client = Dalli::Client.new('localhost:11211', namespace: '...')
Circuitry::Memory::Memcache.new(client: client)

# pass in dalli options
Circuitry::Memory::Memcache.new(host: 'localhost:11211', namespace: '...')
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release` to create a git tag for the version, push git commits
and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/kapost/circuitry/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
