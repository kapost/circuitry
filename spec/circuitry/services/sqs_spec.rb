require 'spec_helper'

sqs_class = Class.new do
  include Circuitry::Services::SQS
end

RSpec.describe sqs_class, type: :model do
  describe '#sqs' do
    before do
      allow(Circuitry.config).to receive(:aws_options).and_return(aws_options)
    end

    let(:aws_options) { { aws_access_key_id: 'foo', aws_secret_access_key: 'bar' } }

    it 'returns a fog SQS instance' do
      expect(subject.sqs).to be_a Fog::AWS::SQS::Real
    end

    it 'uses the AWS configuration options' do
      expect(Fog::AWS::SQS).to receive(:new).with(aws_options)
      subject.sqs
    end
  end
end
