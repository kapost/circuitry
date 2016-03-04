class TestMiddleware
  attr_accessor :log

  def initialize(log: [])
    self.log = log
  end

  def call(*args)
    log << 'before'
    log.concat(args)
    yield
  ensure
    log << 'after'
  end
end

class TestMiddleware2 < TestMiddleware
end
