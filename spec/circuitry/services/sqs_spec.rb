require 'spec_helper'

sqs_class = Class.new do
  include Circuitry::Services::SQS
end

RSpec.describe sqs_class, type: :model do
  describe '#sqs' do
    before do
      allow(Circuitry.config).to receive(:aws_options).and_return(aws_options)
    end

    let(:aws_options) { { access_key_id: 'foo', secret_access_key: 'bar', region: 'us-east-1' } }

    it 'returns an SQS instance' do
      expect(subject.sqs).to be_an Aws::SQS::Client
    end

    it 'uses the AWS configuration options' do
      expect(Aws::SQS::Client).to receive(:new).with(aws_options)
      subject.sqs
    end
  end
end
