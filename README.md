# Concord

Notification pub/sub and message queue processing using Amazon
[SNS](http://aws.amazon.com/sns/) & [SQS](http://aws.amazon.com/sqs/).

[![Code Climate](https://codeclimate.com/repos/55720235e30ba0148f003033/badges/697cd6b997cc25e808f3/gpa.svg)](https://codeclimate.com/repos/55720235e30ba0148f003033/feed)
[![Test Coverage](https://codeclimate.com/repos/55720235e30ba0148f003033/badges/697cd6b997cc25e808f3/coverage.svg)](https://codeclimate.com/repos/55720235e30ba0148f003033/coverage)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'concord'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install concord

## Usage

Concord is configured via its configuration object.

```ruby
Concord.config do |c|
  c.access_key = 'YOUR_AWS_ACCESS_KEY'
  c.secret_key = 'YOUR_AWS_SECRET_KEY'
  c.region = 'us-east-1'
  c.logger = Rails.logger
  c.error_handler = proc do |error|
    HoneyBadger.notify(error)
    HoneyBadger.flush
  end
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
* `error_handler`: An object that responds to `call` with to arguments: the
  deserialized message contents and the topic name used when publishing to SNS.
  *(optional, default: `nil`)*

### Publishing

Publishing is done via the `Concord.publish` method.  It accepts a topic name
the represents the SNS topic along with any non-nil object, representing the data
to be serialized.  Whatever object is called will have its `to_json` method
called for serialization.

```ruby
obj = { foo: 'foo', bar: 'bar' }
Concord.publish('any-topic-name', obj, options)
```

The `publish` method also accepts options that impact instantiation of the
`Publisher` object, though they are not currently utilized.

```ruby
obj = { foo: 'foo', bar: 'bar' }
options = { ... }
Concord.publish('my-topic-name', obj, options)
```

Alternatively, if your options hash will remain unchanged, you can build a single
`Publisher` object to use for all publishing.

```ruby
options = { ... }
publisher = Concord::Publisher.new(options)
publisher.publish('my-topic-name', obj)
```

### Subscribing

Subscribing is done via the `Concord.subscribe` method.  It accepts an SQS queue
URL and takes a block for processing each message.

```ruby
Concord.subscribe('https://sqs.us-east-1.amazonaws.com/ACCOUNT-ID/QUEUE-NAME') do |message, topic_name|
  puts "Received #{topic_name} message: #{message.inspect}"
end
```

The `subscribe` method also accepts options that impact instantiation of the
`Subscriber` object, which currently accepts the following options.

* `:wait_time` - The number of seconds to wait for messages while connected to
  SQS.  Anything above 0 results in long-polling, while 0 results in
  short-polling.  (default: 10)
* `:batch_size` - The number of messages to retrieve in a single SQS request.
  (default: 10)

```ruby
Concord.subscribe('https://...', wait_time: 60, batch_size: 20) do |message, topic_name|
  # ...
end
```

Alternatively, if your options hash will remain unchanged, you can build a single
`Subscriber` object to use for all subscribing.

```ruby
options = { ... }
subscriber = Concord::Subscriber.new(options)
subscriber.subscribe('https://...') do |message, topic_name|
  # ...
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release` to create a git tag for the version, push git commits
and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/kapost/concord/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
