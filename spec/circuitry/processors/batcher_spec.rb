require 'spec_helper'

RSpec.describe Circuitry::Processors::Batcher, type: :model do
  subject { described_class }

  it { is_expected.to be_a Circuitry::Processor }

  describe '.batch' do
    let(:pool) { double('Array', '<<': []) }
    let(:block) { ->{ } }

    before do
      allow(subject).to receive(:pool).and_return(pool)
    end

    it 'adds the block to the pool' do
      subject.batch(&block)
      expect(pool).to have_received(:<<).with(block)
    end
  end

  describe '.flush' do
    let(:pool) { [->{ }, ->{ }] }

    before do
      allow(subject).to receive(:pool).and_return(pool)
    end

    it 'calls each block' do
      subject.flush
      pool.each { |block| expect(block).to have_received(:call) }
    end

    it 'clears the pool' do
      subject.flush
      expect(pool).to be_empty
    end
  end
end
