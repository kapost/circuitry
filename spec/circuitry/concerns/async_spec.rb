require 'spec_helper'

async_class = Class.new do
  include Circuitry::Concerns::Async

  def self.async_strategies
    [:fork, :thread, :batch]
  end

  def config
    Circuitry.subscriber_config
  end
end

RSpec.describe Circuitry::Concerns::Async, type: :model do
  subject { async_class.new }

  describe '#async=' do
    describe 'with an invalid symbol' do
      it 'raises an error' do
        expect { subject.async = :foo }.to raise_error(ArgumentError)
      end
    end

    describe 'with a valid symbol' do
      it 'sets async to the provided symbol' do
        expect { subject.async = :thread }.to change { subject.async }.to(:thread)
      end
    end

    describe 'with :fork when forking is not supported' do
      it 'raises an error' do
        allow(subject).to receive(:platform_supports_forking?).and_return(false)
        expect { subject.async = :fork }.to raise_error(Circuitry::NotSupportedError)
      end
    end

    describe 'with true' do
      it 'sets async to the default value' do
        expect { subject.async = true }.to change { subject.async }.to(subject.config.async_strategy)
      end
    end

    describe 'with false' do
      it 'sets async to false' do
        expect { subject.async = false }.to change { subject.async }.to(false)
      end
    end
  end

  describe '#async?' do
    describe 'when async is a symbol' do
      before do
        subject.async = :thread
      end

      it 'returns true' do
        expect(subject).to be_async
      end
    end

    describe 'when async is false' do
      before do
        subject.async = false
      end

      it 'returns false' do
        expect(subject).to_not be_async
      end
    end
  end

  describe '#process_asynchronously' do
    let(:block) { ->(_) { } }
    let(:processor) { double('Circuitry::Processor', process: nil, wait: nil, is_a?: true) }

    shared_examples_for 'an asynchronous processor' do
      before do
        allow(Circuitry::Pool).to receive(:<<)
      end

      it 'delegates to the processor' do
        subject.process_asynchronously(&block)
        expect(processor).to have_received(:process)
      end

      it 'adds the processor to the pool' do
        subject.process_asynchronously(&block)
        expect(Circuitry::Pool).to have_received(:<<).with(processor)
      end
    end

    describe 'via forking' do
      before do
        allow(subject).to receive(:async).and_return(:fork)
        allow(Circuitry::Processors::Forker).to receive(:new).with(any_args, &block).and_return(processor)
      end

      it_behaves_like 'an asynchronous processor'
    end

    describe 'via threading' do
      before do
        allow(subject).to receive(:async).and_return(:thread)
        allow(Circuitry::Processors::Threader).to receive(:new).with(any_args, &block).and_return(processor)
      end

      it_behaves_like 'an asynchronous processor'
    end

    describe 'via batching' do
      before do
        allow(subject).to receive(:async).and_return(:batch)
        allow(Circuitry::Processors::Batcher).to receive(:new).with(any_args, &block).and_return(processor)
      end

      it_behaves_like 'an asynchronous processor'
    end
  end
end
