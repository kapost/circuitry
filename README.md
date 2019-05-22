# Circuitry

[![Code Climate](https://codeclimate.com/github/kapost/circuitry/badges/gpa.svg)](https://codeclimate.com/github/kapost/circuitry)
[![Test Coverage](https://codeclimate.com/github/kapost/circuitry/badges/coverage.svg)](https://codeclimate.com/github/kapost/circuitry/coverage)

Decouple ruby applications using [SNS](http://aws.amazon.com/sns/) fanout with [SQS](http://aws.amazon.com/sqs/) processing.

A Circuitry publisher application can broadcast events which can be fanned out to any number of SQS queues. This technique is a [common approach](http://docs.aws.amazon.com/sns/latest/dg/SNS_Scenarios.html) to implementing an enterprise message bus. For example, applications which care about billing or new user onboarding can react when a user signs up, without the origin web application being concerned with those domains. In this way, new capabilities can be connected to an enterprise system without change proliferation.

## Features

What circuitry provides:

* *Decoupling:* apps can send and receive messages to each other without explicitly coding destinations into your app.
* *Fan-out:* multiple queues (i.e.: multiple apps) can receive the same message by publishing it a single time.
* *Reliability:* if your app goes down (intentionally or otherwise), messages will be waiting in the queue whenever it starts up again.
* *Speed:* because it's built on AWS, message delivery and receipt is *fast*.
* *Duplication:* although SQS messages can be delivered multiple times, circuitry safeguards to ensure they're only received by your app once.
* *Retries:* if a received message fails to be processed, it will be retried (unless otherwise configured).
* *Customization:* configure your publisher and subscriber to behave the way each app independently expects.

What circuitry does not provide:

* *Ordering:* messages may not arrive in the order they were sent.
* *Scheduling:* messages are processed as they're received.

## Example

A [circuitry-example](https://github.com/kapost/circuitry-example) app is available to quickly try the gem on your own AWS account.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'circuitry', '~> 3.1'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install circuitry

## Usage

Circuitry is configured via its configuration object or via circuitry.yml config.

```ruby
Circuitry.subscriber_config do |c|
  c.queue_name = "#{Rails.env}-appname"
  c.dead_letter_queue_name = "#{Rails.env}-appname-failures"
  c.max_receive_count = 8
  c.access_key = 'YOUR_AWS_ACCESS_KEY'
  c.secret_key = 'YOUR_AWS_SECRET_KEY'
  c.region = 'us-east-1'
  c.logger = Rails.logger
  c.error_handler = proc do |error|
    HoneyBadger.notify(error)
    HoneyBadger.flush
  end
  c.lock_strategy = Circuitry::Locks::Redis.new(url: 'redis://localhost:6379')
  c.async_strategy = :thread
  c.on_async_exit = proc { Mongoid.disconnect_sessions }
end

Circuitry.publisher_config do |c|
  c.access_key = 'YOUR_AWS_ACCESS_KEY'
  c.secret_key = 'YOUR_AWS_SECRET_KEY'
  c.region = 'us-east-1'
  c.logger = Rails.logger
  c.error_handler = proc do |error|
    HoneyBadger.notify(error)
    HoneyBadger.flush
  end
  c.async_strategy = :batch
end
```

Many of the advanced options, such as `error_handler` or `async_strategy` require this initializer-
style configuration. A simpler option is available via config/circuitry.yml
(or config/circuitry.yml.erb):

```yml
---
access_key: "YOUR_AWS_ACCESS_KEY"
secret_key: "YOUR_AWS_SECRET_KEY"
region: "us-east-1"

development:
  publisher:
    topic_names:
      - brandonc-appname-user-create
      - brandonc-appname-user-destroy
  subscriber:
    queue_name: "brandonc-appname"
    dead_letter_queue_name: "brandonc-appname-failures"
    topic_names:
      - brandonc-otherapp-content-create
      - brandonc-otherapp-content-destroy
production:
  publisher:
    topic_names:
      - production-appname-user-create
      - production-appname-user-destroy
  subscriber:
    queue_name: "production-appname"
    dead_letter_queue_name: "production-appname-failures"
    topic_names:
      - production-otherapp-content-create
      - production-otherapp-content-destroy
```

Available configuration options for *both* subscriber and publisher applications include:

* `access_key`: The AWS access key ID that has access to SNS publishing and/or
  SQS subscribing. *(required unless using iam profile)*
* `secret_key`: The AWS secret access key that has access to SNS publishing
  and/or SQS subscribing. *(required unless using iam profile)*
* `use_iam_profile`: Whether or not to use an iam profile for authenticating to AWS.
  This will only work when running your application inside of an AWS instance.
  Accepts `true` or `false`
  Please refer to the [AWS Docs](http://docs.aws.amazon.com/sdk-for-ruby/v2/developer-guide/setup-config.html#aws-ruby-sdk-credentials-iam)
  for more details about using iam profiles for authentication.
  *(required unless using access and secret keys, default: `false`)*
* `region`: The AWS region that your SNS and/or SQS account lives in.
  *(optional, default: "us-east-1")*
* `logger`: The logger to use for informational output, warnings, and error
  messages. *(optional, default: `Logger.new(STDOUT)`)*
* `error_handler`: An object that responds to `call` with two arguments: the
  deserialized message contents and the topic name used when publishing to SNS.
  *(optional, default: `nil`)*
* `async_strategy`: One of `:fork`, `:thread`, or `:batch` that
  determines how asynchronous publish requests are processed. *(optional,
  default: `:fork`)*
  * `:fork`: Forks a detached child process that immediately sends the request.
  * `:thread`: Creates a new thread that immediately sends the request. Because
    threads are not guaranteed to complete when the process exits, completion can
    be ensured by calling `Circuitry.flush`.
  * `:batch`: Stores the request in memory to be submitted later. Batched
    requests must be manually sent by calling `Circuitry.flush`. Only valid as a
    publishing strategy
* `on_async_exit`: An object that responds to `call`. This is useful for
  managing shared resources such as database connections that require closing.
  *(optional, default: `nil`)*
* `topic_names`: An array of topic names that your application will
  publish and/or subscribe to. This configuration is only used during provisioning.
* `middleware`: A chain of middleware that messages must go through when sent or received.
  Please refer to the [Middleware](#middleware) section for more details regarding this
  option.

Available configuration options for subscriber applications include:

* `queue_name`: The name of the SQS queue that your subscriber application
  will listen to. This queue will be created or configured during provisioning.
* `dead_letter_queue_name`: The name of the SQS dead letter queue that will be
  used after all retries fail. This configuration value is only used during provisioning.
  *(optional, default: `<subscriber_queue_name>-failures`)*
* `lock_strategy` - The store used to ensure that no duplicate messages are
  processed. Please refer to the [Lock Strategies](#lock-strategies) section for
  more details regarding this option. *(default: `Circuitry::Locks::Memory.new`)*
* `max_receive_count` - The number of times a message will be received by the queue after
  unsuccessful attempts to process it before it is discarded or added to the
  `dead_letter_queue_name` queue. This configuration value is only used during
  provisioning. *(optional, default: 8)*
* `visibility_timeout` - A period of time during which Amazon SQS prevents other subscribers from
  receiving and processing that message (before it is deleted by circuitry after being processed
  successfully.) This configuration value is only used during provisioning.
  *(optional, default: 1800)*

### Provisioning

You can automatically provision SQS queues, SNS topics, and the subscriptions between them using
two methods: the circuitry CLI or the `rake circuitry:setup` task. The rake task will provision the
subscriber queue and publishing topics that are configured within your application.

```ruby
require 'circuitry/tasks'

Circuitry.subscriber_config do |c|
  c.queue_name = 'myapp-production-events'
  c.topic_names = ['theirapp-production-stuff-created', 'theirapp-production-stuff-deleted']
end
```

When provisioning, a dead letter queue is also created using the name "<queue_name>-failures". You
can customize the dead letter queue name in your configuration.

Run `circuitry help provision` for help using CLI provisioning.

### Publishing

Publishing is done via the `Circuitry.publish` method. It accepts a topic name
that represents the SNS topic along with any non-nil object, representing the
data to be serialized. Whatever object is called will have its `to_json` method
called for serialization.

```ruby
obj = { foo: 'foo', bar: 'bar' }
Circuitry.publish('any-topic-name', obj)
```

The `publish` method also accepts options that impact instantiation of the
`Publisher` object, which currently includes the following options.

* `:async` - Whether or not publishing should occur in the background. Accepts
  one of `:fork`, `:thread`, `:batch`, `true`, or `false`. Passing `true` uses
  the `async_strategy` value from the gem configuration. Please refer to
  the [Asynchronous Support](#asynchronous-support) section for more details
  regarding this option. *(default: `false`)*
* `:timeout` - The maximum amount of time in seconds that publishing a message
  will be attempted before giving up. If the timeout is exceeded, an exception
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

Subscribing is done via the `Circuitry.subscribe` method. It accepts a block for processing each
message. This method **indefinitely blocks**, processing messages as they are enqueued.

```ruby
Circuitry.subscribe do |message, topic_name|
  puts "Received #{topic_name} message: #{message.inspect}"
end
```

The `subscribe` method also accepts options that impact instantiation of the
`Subscriber` object, which currently includes the following options.

* `:lock` - The strategy used to ensure that no duplicate messages are processed.
  Accepts `true`, `false`, or an instance of a class inheriting from
  `Circuitry::Locks::Base`. Passing `true` uses the `lock_strategy` value from
  the gem configuration. Passing `false` uses the [NOOP](#NOOP) strategy. Please
  refer to the [Lock Strategies](#lock-strategies) section for more details
  regarding this option. *(default: `true`)*
* `:async` - Whether or not subscribing should occur in the background. Accepts
  one of `:fork`, `:thread`, `true`, or `false`. Passing `true` uses the
  `async_strategy` value from the gem configuration. Passing an
  asynchronous value will cause messages to be handled concurrently. Please
  refer to the [Asynchronous Support](#asynchronous-support) section for more
  details regarding this option. *(default: `false`)*
* `:timeout` - The maximum amount of time in seconds that processing a message
  will be attempted before giving up. If the timeout is exceeded, an exception
  will raised to be handled by your application or `error_handler`. *(default:
  15)*
* `:wait_time` - The number of seconds to wait for messages while connected to
  SQS. Anything above 0 results in long-polling, while 0 results in
  short-polling. *(default: 10)*
* `:batch_size` - The number of messages to retrieve in a single SQS request.
  *(default: 10)*

```ruby
options = {
  lock: true,
  async: true,
  timeout: 20,
  wait_time: 60,
  batch_size: 20
}

Circuitry.subscribe(options) do |message, topic_name|
  # ...
end
```

Alternatively, if your options hash will remain unchanged, you can build a single
`Subscriber` object to use for all subscribing.

```ruby
options = { ... }
subscriber = Circuitry::Subscriber.new(options)
subscriber.subscribe do |message, topic_name|
  # ...
end
```

### Asynchronous Support

Publishing supports three asynchronous strategies (forking, threading, and
batching) while subscribing supports two (forking and threading).

#### Forking

When forking a child process, that child is detached so that your application
does not need to worry about waiting for the process to finish. Forked requests
begin processing immediately and do not have any overhead in terms of waiting for
them to complete.

There are two important notes regarding forking in general as it relates to
asynchronous support:

1. Forking is not supported on all platforms (e.g.: Windows and NetBSD 4),
   requiring that your implementation use synchronous requests or an alternative
   asynchronous strategy in such circumstances.

2. Forking results in resources being copied from the parent process to the child
   process. In order to prevent database connection errors and the like, you
   should properly handle closing and reopening resources before and after
   forking, respectively. For example, if you are using Rails with Unicorn, you
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

Threaded publish and subscribe requests begin processing immediately. Unlike
forking, it's up to you to ensure that all threads complete before your
application exits. This can be done by calling `Circuitry.flush`.

#### Batching

Batched publish and subscribe requests are queued in memory and do not begin
processing until you explicit flush them. This can be done by calling
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
that denotes the message has finished processing.

The soft lock has a default TTL of 5 minutes (a seemingly sane amount of time
during which processing most queue messages should certainly be able to
complete), while the hard lock has a default TTL of 24 hours (based upon
[a suggestion by an AWS employee](https://forums.aws.amazon.com/thread.jspa?threadID=140782#507605)).
The soft and hard TTL values can be changed by passing a `:soft_ttl` or
`:hard_ttl` value to the lock initializer, representing the number of seconds
that a lock should persist. For example:

```ruby
Circuitry.subscriber_config.lock_strategy = Circuitry::Locks::Memory.new(
    soft_ttl: 10 * 60,      # 10 minutes
    hard_ttl: 48 * 60 * 60  # 48 hours
)
```

#### Memory

If not specified in your circuitry configuration, the memory store will be used
by default. This lock strategy is provided as the lowest barrier to entry given
that it has no third-party dependencies. It should be avoided if running
multiple subscriber processes or if expecting a high throughput that would result
in a large amount of memory consumption.

```ruby
Circuitry::Locks::Memory.new
```

#### Redis

Using the redis lock strategy requires that you add `gem 'redis'` to your
`Gemfile`, as it is not included bundled with the circuitry gem by default.

There are two ways to use the redis lock strategy. The first is to pass your
redis connection options to the lock in the same way that you would when building
a new `Redis` object.

```ruby
Circuitry::Locks::Redis.new(url: 'redis://localhost:6379')
```

The second way is to pass in a `:client` option that specifies either the redis
client itself or a [ConnectionPool](https://github.com/mperham/connection_pool)
of redis clients. This is useful for more advanced usage such as sharing an
existing redis connection, connection pooling, utilizing
[Redis::Namespace](https://github.com/resque/redis-namespace), or utilizing
[hiredis](https://github.com/redis/hiredis-rb).

```ruby
client = Redis.new(url: 'redis://localhost:6379')
Circuitry::Locks::Redis.new(client: client)

client = ConnectionPool.new(size: 5) { Redis.new }
Circuitry::Locks::Redis.new(client: client)
```

#### Memcache

Using the memcache lock strategy requires that you add `gem 'dalli'` to your
`Gemfile`, as it is not included bundled with the circuitry gem by default.

There are two ways to use the memcache lock strategy. The first is to pass your
dalli connection host and options to the lock in the same way that you would when
building a new `Dalli::Client` object. The special `host` option will be treated
as the memcache host, just as the first argument to `Dalli::Client`.

```ruby
Circuitry::Locks::Memcache.new(host: 'localhost:11211', namespace: '...')
```

The second way is to pass in a `:client` option that specifies the dalli client
itself. This is useful for sharing an existing memcache connection.

```ruby
client = Dalli::Client.new('localhost:11211', namespace: '...')
Circuitry::Locks::Memcache.new(client: client)
```

#### NOOP

Using the noop lock strategy permits you to continue to treat SQS as a
distributed queue in a true sense, meaning that you might receive duplicate
messages. Please refer to the Amazon SQS documentation pertaining to the
[Properties of Distributed Queues](http://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/DistributedQueues.html).

#### Custom

It's also possible to roll your own lock strategy. Simply create a class that
includes (or module that extends) `Circuitry::Locks::Base` and implements the
following methods:

* `lock`: Accepts the `key` and `ttl` as parameters. If the key is already
  locked, this method must return false. If the key is not already locked, it
  must lock the key for `ttl` seconds and return true. It is important that
  the check and update are **atomic** in order to ensure the same message isn't
  processed more than once.
* `lock!`: Accepts the `key` and `ttl` as parameters. Must lock the key for
  `ttl` seconds regardless of whether or not the key was previously locked.
* `unlock!`: Accepts the `key` as a parameter. Must unlock (delete) the key if
  it was previously locked.

For example, a database-backed solution might look something like the following:

```ruby
class DatabaseLockStrategy
  include Circuitry::Locks::Base

  def initialize(options = {})
    super(options)
    self.connection = options.fetch(:connection)
  end

  protected

  def lock(key, ttl)
    connection.exec("INSERT INTO locks (key, expires_at) VALUES ('#{key}', '#{Time.now + ttl}')")
  end

  def lock!(key, ttl)
    connection.exec("UPSERT INTO locks (key, expires_at) VALUES ('#{key}', '#{Time.now + ttl}')")
  end

  def unlock!(key)
    connection.exec("DELETE FROM locks WHERE key = '#{key}'")
  end

  private

  attr_reader :connection
end
```

To use, simply create an instance of the class with your necessary options, and
pass your lock instance to the configuration as the `:lock_strategy`.

```ruby
connection = PG.connect(...)
Circuitry.subcriber_config.lock_strategy = DatabaseLockStrategy.new(connection: connection)
```

### Middleware

Circuitry middleware can be used to perform additional processing around a message
being sent by a publisher or received by a subscriber.  Some examples of processing
that belong here are monitoring or encryption specific to your application.

Middleware can be added to the publisher, the subscriber, or both.  A middleware
class is defined by an (optional) `#initialize` method that accepts any number of
arguments, as well as a `#call` method that accepts the `topic` string, `message`
string, and a block for continuing processing.

For example, a simple logging middleware might look something like the following:

```ruby
class LoggerMiddleware
  attr_reader :namespace, :logger

  def initialize(namespace:, logger: Logger.new(STDOUT))
    self.namespace = namespace
    self.logger = logger
  end

  def call(topic, message)
    logger.info("#{namespace} (start): #{topic} - #{message}")
    yield
  ensure
    logger.info("#{namespace} (done): #{topic} - #{message}")
  end

  private

  attr_writer :namespace, :logger
end
```

Adding the middleware to the stack happens through the Circuitry config.

```ruby
Circuitry.subscriber_config do |config|
  # single-line format
  config.middleware.add LoggerMiddleware, namespace: 'subscriber_app', logger: Rails.logger

  # block format
  config.middleware do |chain|
    chain.add LoggerMiddleware, namespace: 'subscriber_app', logger: Rails.logger
  end
end

Circuitry.publisher_config do |config|
  # single-line format
  config.middleware.add LoggerMiddleware, namespace: 'publisher_app'

  # block format
  config.middleware do |chain|
    chain.add LoggerMiddleware, namespace: 'publisher_app'
  end
end
```

`config.middleware` responds to a handful of methods that can be used for configuring
your middleware:

* `#add`: Appends a middleware class to the end of the chain.  If the class already exists, it is
  replaced.
  * `middleware.add NewMiddleware, arg1, arg2, ...`
* `#prepend`: Prepends a middleware class to the beginning of the chain.  If the class already
  exists, it is replaced.
  * `middleware.prepend NewMiddleware, arg1, arg2, ...`
* `#remove`: Removes a middleware class from anywhere in the chain.
  * `middleware.remove NewMiddleware`
* `#insert_before`: Injects a middleware class before another middleware class in the chain.  If
  the other class does not exist in the chain, this behaves the same as `#prepend`.
  * `middleware.insert_before ExistingMiddleware, NewMiddleware, arg1, arg2...`
* `#insert_after`: Injects a middleware class after another middleware class in the chain.  If the
  other class does not exist in the chain, this behaves the same as `#add`.
  * `middleware.insert_after ExistingMiddleware, NewMiddleware, arg1, arg2...`
* `#clear`: Removes all middleware classes from the chain.
  * `middleware.clear`

## Testing

Circuitry provides a simple option for testing publishing and subscribing without actually hitting
Amazon services.  Inside your test suite (e.g.: `spec_helper.rb`), just make sure you include the
following line:

```ruby
require 'circuitry/testing'
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release` to create a git tag for the version, push git commits
and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it (https://github.com/kapost/circuitry/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Update the changelog
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request
