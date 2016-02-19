require 'spec_helper'

RSpec.describe Circuitry::Config::FileLoader do
  subject { described_class }

  describe '.load' do
    context 'with valid fixture' do
      before do
        subject.load('spec/support/fixtures/example_config.yml.erb', 'test')
      end

      it 'loads publisher config' do
        expect(Circuitry.subscriber_config.queue_name).to eql('app-production-queuename')
      end

      it 'loads aws settings' do
        expect(Circuitry.subscriber_config.aws_options).to eql(
          access_key_id:     'test_access_key',
          secret_access_key: 'test_secret_key',
          region:            'us-east-1'
        )
      end

      it 'coerces integers' do
        expect(Circuitry.subscriber_config.max_receive_count).to eql(4)
      end
    end

    context 'with invalid fixture' do
      it 'raises ConfigError' do
        expect {
          subject.load('spec/support/fixtures/invalid_config.yml', 'test')
        }.to raise_error(Circuitry::ConfigError)
      end
    end
  end
end
