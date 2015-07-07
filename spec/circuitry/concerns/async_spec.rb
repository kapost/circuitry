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
    before do
      allow(subject).to receive(:fork).and_return(pid)
      allow(Process).to receive(:detach)
    end

    let(:block) { ->{ } }
    let(:pid) { 'pid' }

    describe 'via forking' do
      pending
    end

    describe 'via threading' do
      pending
    end

    describe 'via batching' do
      pending
    end

    # describe 'when platform supports async' do
    #   before do
    #     allow(subject).to receive(:platform_supports_forking?).and_return(true)
    #   end
    #
    #   it 'forks a process' do
    #     subject.process_asynchronously(&block)
    #     expect(subject).to have_received(:fork)
    #   end
    #
    #   it 'detaches the forked process' do
    #     subject.process_asynchronously(&block)
    #     expect(Process).to have_received(:detach).with(pid)
    #   end
    # end

    # describe 'when platform does not support async' do
    #   before do
    #     allow(subject).to receive(:platform_supports_async?).and_return(false)
    #   end
    #
    #   it 'raises an error' do
    #     expect { subject.process_asynchronously(&block) }.to raise_error(Circuitry::NotSupportedError)
    #   end
    # end
  end
end
