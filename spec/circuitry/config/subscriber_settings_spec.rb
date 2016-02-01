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
end
