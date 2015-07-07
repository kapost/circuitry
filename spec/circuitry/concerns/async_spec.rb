require 'spec_helper'

async_class = Class.new do
  include Circuitry::Concerns::Async

  def self.default_async_strategy
    :fork
  end
end

RSpec.describe async_class, type: :model do
  describe '#async=' do
    pending
  end

  describe '#async?' do
    pending
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
