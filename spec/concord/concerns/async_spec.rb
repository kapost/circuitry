require 'spec_helper'

async_class = Class.new do
  include Concord::Concerns::Async
end

RSpec.describe async_class, type: :model do
  describe '#process_asynchronously' do
    before do
      allow(subject).to receive(:fork).and_return(pid)
      allow(Process).to receive(:detach)
    end

    let(:block) { ->{ } }
    let(:pid) { 'pid' }

    describe 'when platform supports async' do
      before do
        allow(subject).to receive(:platform_supports_async?).and_return(true)
      end

      it 'forks a process' do
        subject.process_asynchronously(&block)
        expect(subject).to have_received(:fork)
      end

      it 'detaches the forked process' do
        subject.process_asynchronously(&block)
        expect(Process).to have_received(:detach).with(pid)
      end
    end

    describe 'when platform does not support async' do
      before do
        allow(subject).to receive(:platform_supports_async?).and_return(false)
      end

      it 'raises an error' do
        expect { subject.process_asynchronously(&block) }.to raise_error(Concord::NotSupportedError)
      end
    end
  end

  describe '#platform_supports_async?' do
    it 'returns true when delegate returns true' do
      allow(Concord).to receive(:platform_supports_async?).and_return(true)
      expect(subject).to be_platform_supports_async
    end

    it 'returns false when delegate returns false' do
      allow(Concord).to receive(:platform_supports_async?).and_return(false)
      expect(subject).to_not be_platform_supports_async
    end
  end
end
