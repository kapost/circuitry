require 'spec_helper'

RSpec.describe Circuitry::Config::SubscriberSettings do
  describe '#async_strategy=' do
    it_behaves_like 'a validated setting', Circuitry::Subscriber.async_strategies, :async_strategy
  end

  describe '#queue_name' do
    it 'sets #dead_letter_queue_name' do
      expect {
        subject.queue_name = 'awesome'
      }.to change(subject, :dead_letter_queue_name).to('awesome-failures')
    end

    context 'dead_letter_queue_name is set' do
      before do
        subject.dead_letter_queue_name = 'dawson'
      end

      it 'does not set #dead_letter_queue_name' do
        expect {
          subject.queue_name = 'awesome'
        }.to_not change(subject, :dead_letter_queue_name)
      end
    end
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

    context 'with overrides' do
      before do
        subject.aws_options_overrides = {
          endpoint: 'http://localhost:4566'
        }
      end

      it 'includes the overrides in AWS connection options hash' do
        expect(subject.aws_options).to eq(access_key_id: 'access_key', secret_access_key: 'secret_key', region: 'region', endpoint: 'http://localhost:4566')
      end
    end
  end

  describe '#middleware' do
    it_behaves_like 'middleware settings'
  end
end
