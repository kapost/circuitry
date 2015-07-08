require 'spec_helper'

async_class = Class.new do
  include Circuitry::Concerns::Async

  def self.default_async_strategy
    :thread
  end

  def self.async_strategies
    [:fork, :thread, :batch]
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
        expect(subject.class).to receive(:default_async_strategy).at_least(:once).and_call_original
        subject.async = true
        expect(subject.async).to eq subject.class.default_async_strategy
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
    let(:block) { ->{ } }

    describe 'via forking' do
      before do
        allow(subject).to receive(:async).and_return(:fork)
      end

      it 'delegates to fork processor' do
        expect(Circuitry::Processors::Forker).to receive(:process).with(no_args, &block)
        subject.process_asynchronously(&block)
      end
    end

    describe 'via threading' do
      before do
        allow(subject).to receive(:async).and_return(:thread)
      end

      it 'delegates to thread processor' do
        expect(Circuitry::Processors::Threader).to receive(:process).with(no_args, &block)
        subject.process_asynchronously(&block)
      end
    end

    describe 'via batching' do
      before do
        allow(subject).to receive(:async).and_return(:batch)
      end

      it 'delegates to batch processor' do
        expect(Circuitry::Processors::Batcher).to receive(:process).with(no_args, &block)
        subject.process_asynchronously(&block)
      end
    end
  end
end
