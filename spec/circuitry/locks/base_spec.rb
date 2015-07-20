require 'spec_helper'

lock_class = Class.new do
  include Circuitry::Locks::Base

  def lock(key, ttl)
  end

  def lock!(key, ttl)
  end
end

incomplete_lock_class = Class.new do
  include Circuitry::Locks::Base
end

RSpec.describe Circuitry::Locks::Base, type: :model do
  subject { lock_class.new }

  describe '#soft_lock' do
    let(:id) { SecureRandom.hex(100) }

    describe 'when the class has defined #lock' do
      it 'delegates to the #lock method' do
        expect(subject).to receive(:lock).with("circuitry:lock:#{id}", described_class::DEFAULT_SOFT_TTL)
        subject.soft_lock(id)
      end

      it 'does not raise an error' do
        expect { subject.soft_lock(id) }.to_not raise_error
      end
    end

    describe 'when the class has not defined #lock' do
      subject { incomplete_lock_class.new }

      it 'raises an error' do
        expect { subject.soft_lock(id) }.to raise_error(NotImplementedError)
      end
    end
  end

  describe '#hard_lock' do
    let(:id) { SecureRandom.hex(100) }

    describe 'when the class has defined #lock!' do
      it 'delegates to the #lock! method' do
        expect(subject).to receive(:lock!).with("circuitry:lock:#{id}", described_class::DEFAULT_HARD_TTL)
        subject.hard_lock(id)
      end

      it 'does not raise an error' do
        expect { subject.hard_lock(id) }.to_not raise_error
      end
    end

    describe 'when the class has not defined #lock!' do
      subject { incomplete_lock_class.new }

      it 'raises an error' do
        expect { subject.hard_lock(id) }.to raise_error(NotImplementedError)
      end
    end
  end
end
