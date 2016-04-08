require 'spec_helper'

RSpec.describe Circuitry::Config::PublisherSettings do
  describe '.new' do
    context 'initialized with a hash' do
      subject { described_class.new(secret_key: '123', region: 'us-west-1') }

      it 'is configured' do
        expect(subject.secret_key).to eql('123')
      end
    end
  end

  describe '#async_strategy=' do
    it_behaves_like 'a validated setting', Circuitry::Publisher.async_strategies, :async_strategy
  end

  describe '#aws_options' do
    before do
      subject.access_key = 'access_key'
      subject.secret_key = 'secret_key'
      subject.region = 'region'
    end

    it 'returns a hash of AWS connection options' do
      expect(subject.aws_options).to eq(access_key_id: 'access_key', secret_access_key: 'secret_key', region: 'region')
    end
  end

  describe '#middleware' do
    it_behaves_like 'middleware settings'
  end
end
