require 'spec_helper'

RSpec.describe Circuitry::Processors::Threader, type: :model do
  subject { described_class }

  it { is_expected.to be_a Circuitry::Processor }

  describe '.process' do
    let(:pool) { double('Array', '<<': []) }
    let(:block) { ->{ } }
    let(:thread) { double('Thread', join: true) }

    before do
      allow(subject).to receive(:pool).and_return(pool)
      allow(Thread).to receive(:new).and_return(thread)
    end

    it 'wraps the block in a thread' do
      subject.process(&block)
      expect(Thread).to have_received(:new).with(no_args, &block)
    end

    it 'adds the thread to the pool' do
      subject.process(&block)
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

  describe 'when on_thread_exit is defined' do
    let(:block) { ->{ } }
    let(:on_thread_exit) { double('Proc', call: true) }

    before do
      allow(Circuitry.config).to receive(:on_thread_exit).and_return(on_thread_exit)
    end

    it 'calls the proc' do
      subject.process(&block)
      subject.flush
      expect(on_thread_exit).to have_received(:call)
    end
  end
end
