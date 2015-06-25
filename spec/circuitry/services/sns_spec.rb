require 'spec_helper'

sns_class = Class.new do
  include Circuitry::Services::SNS
end

RSpec.describe sns_class, type: :model do
  describe '#sns' do
    before do
      allow(Circuitry.config).to receive(:aws_options).and_return(aws_options)
    end

    let(:aws_options) { { aws_access_key_id: 'foo', aws_secret_access_key: 'bar' } }

    it 'returns a fog SNS instance' do
      expect(subject.sns).to be_a Fog::AWS::SNS::Real
    end

    it 'uses the AWS configuration options' do
      expect(Fog::AWS::SNS).to receive(:new).with(aws_options)
      subject.sns
    end
  end
end
