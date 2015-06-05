require 'spec_helper'

RSpec.describe Concord::Configuration, type: :model do
  describe '#aws_options' do
    before do
      subject.access_key = 'access_key'
      subject.secret_key = 'secret_key'
      subject.region = 'region'
    end

    it 'returns a hash of AWS connection options' do
      expect(subject.aws_options).to eq(aws_access_key_id: 'access_key', aws_secret_access_key: 'secret_key', region: 'region')
    end
  end
end
