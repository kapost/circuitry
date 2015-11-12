require 'spec_helper'

sns_class = Class.new do
  include Circuitry::Services::SNS
end

RSpec.describe sns_class, type: :model do
  describe '#sns' do
    before do
      allow(Circuitry.config).to receive(:aws_options).and_return(aws_options)
    end

    let(:aws_options) { { access_key_id: 'foo', secret_access_key: 'bar', region: 'us-east-1' } }

    it 'returns an SNS instance' do
      expect(subject.sns).to be_an Aws::SNS::Client
    end

    it 'uses the AWS configuration options' do
      expect(Aws::SNS::Client).to receive(:new).with(aws_options)
      subject.sns
    end
  end
end
