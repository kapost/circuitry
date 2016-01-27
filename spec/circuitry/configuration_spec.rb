require 'spec_helper'

RSpec.describe Circuitry::Configuration, type: :model do
  shared_examples_for 'a validated setting' do |permitted_values, setting_name|
    def set(value)
      subject.public_send(:"#{setting}=", value)
    end

    def get
      subject.public_send(setting)
    end

    let(:setting) { setting_name }

    permitted_values.each do |value|
      describe "with valid value #{value}" do
        it 'does not raise an error' do
          expect { set(value) }.to_not raise_error
        end

        it 'changes the config value' do
          set(value)
          expect(get).to eq value
        end
      end
    end

    describe 'with invalid value' do
      it 'raises an error' do
        expect { set(:fake) }.to raise_error ArgumentError
      end

      it 'does not change the config value' do
        expect { set(:fake) rescue nil }.to_not change { get }
      end
    end
  end

  describe '#publish_async_strategy=' do
    it_behaves_like 'a validated setting', Circuitry::Publisher.async_strategies, :publish_async_strategy
  end

  describe '#subscribe_async_strategy=' do
    it_behaves_like 'a validated setting', Circuitry::Subscriber.async_strategies, :subscribe_async_strategy
  end

  describe '#subscriber_queue_name' do
    it 'sets #subscriber_dead_letter_queue_name' do
      expect {
        subject.subscriber_queue_name = 'awesome'
      }.to change(subject, :subscriber_dead_letter_queue_name).to('awesome-failures')
    end

    context 'subscriber_dead_letter_queue_name is set' do
      before do
        subject.subscriber_dead_letter_queue_name = 'dawson'
      end

      it 'does not set #subscriber_dead_letter_queue_name' do
        expect {
          subject.subscriber_queue_name = 'awesome'
        }.to_not change(subject, :subscriber_dead_letter_queue_name)
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
  end
end
