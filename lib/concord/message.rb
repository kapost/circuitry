module Concord
  class Message
    attr_reader :raw

    def initialize(raw)
      @raw = raw
    end

    def context
      @context ||= JSON.load(raw['Body'])
    end

    def body
      @body ||= JSON.load(context['Message'])
    end

    def id
      raw['MessageId']
    end

    def receipt_handle
      raw['ReceiptHandle']
    end
  end
end
