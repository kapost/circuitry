require 'spec_helper'

RSpec.describe Circuitry::Locks::NOOP, type: :model do
  subject { described_class.new }

  let(:id) { SecureRandom.hex(100) }

  describe '#soft_lock' do
    it 'returns true' do
      expect(subject.soft_lock(id)).to be true
    end
  end

  describe '#lock!' do
    it 'returns nil' do
      expect(subject.hard_lock(id)).to be nil
    end
  end
end
