require 'spec_helper'

RSpec.describe Circuitry::Processors::Forker, type: :model do
  subject { described_class }

  it { is_expected.to be_a Circuitry::Processor }

  describe '.fork' do
    before do
      allow(subject).to receive(:fork).and_return(pid)
      allow(Process).to receive(:detach)
    end

    let(:pid) { 'pid' }
    let(:block) { ->{ } }

    it 'forks a process' do
      subject.process(&block)
      expect(subject).to have_received(:fork)
    end

    it 'detaches the forked process' do
      subject.process(&block)
      expect(Process).to have_received(:detach).with(pid)
    end
  end

  describe '.flush' do
    it 'does nothing' do
      expect { subject.flush }.to_not raise_error
    end
  end
end
