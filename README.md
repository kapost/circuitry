# Concord

Kapost notification pub/sub and message queue processing.

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
  c.region = 'us-east-1'                 # optional, default: 'us-east-1'
  c.logger = Rails.logger                # optional, default: Logger.new(STDOUT)
end
```

### Publishing

Publishing is done via the `Concord.publish` method.  It accepts a topic name
the represents the SNS topic along with any non-nil object, representing the data
to be serialized.  Whatever object is called will have its `to_json` method
called for serialization.

```ruby
obj = { foo: 'foo', bar: 'bar' }
Concord.publish('any-topic-name', obj)
```

### Subscribing

Subscribing is done via the `Concord.subscribe` method.  It accepts an SQS queue
URL and takes a block for processing each message.

```ruby
Concord.subscribe('https://sqs.us-east-1.amazonaws.com/ACCOUNT-ID/QUEUE-NAME') do |message|
  puts message.inspect
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release` to create a git tag for the version, push git commits
and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Improvements

* Failures: it would be nice to set up a failure queue for requeuing, and perhaps
  a maximum number of retries before moving to the failure queue.

## Contributing

1. Fork it ( https://github.com/kapost/concord/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
