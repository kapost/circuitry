require 'spec_helper'

RSpec.describe Circuitry::Processors::Threader, type: :model do
  subject { described_class }

  it { is_expected.to be_a Circuitry::Processor }

  describe '.thread' do
    let(:pool) { double('Array', '<<': []) }
    let(:block) { ->{ } }
    let(:thread) { double('Thread', join: true) }

    before do
      allow(subject).to receive(:pool).and_return(pool)
      allow(Thread).to receive(:new).and_return(thread)
    end

    it 'wraps the block in a thread' do
      subject.thread(&block)
      expect(Thread).to have_received(:new).with(no_args, &block)
    end

    it 'adds the thread to the pool' do
      subject.thread(&block)
      expect(pool).to have_received(:<<).with(thread)
    end
  end

  describe '.flush' do
    let(:pool) { [double('Thread', join: true), double('Thread', join: true)] }

    before do
      allow(subject).to receive(:pool).and_return(pool)
    end

    it 'joins each thread' do
      subject.flush
      pool.each { |thread| expect(thread).to have_received(:join) }
    end

    it 'clears the pool' do
      subject.flush
      expect(pool).to be_empty
    end
  end
end
