require 'spec_helper'

RSpec.describe Circuitry::Processors::Forker, type: :model do
  subject { described_class.new(config, &block) }

  let(:config) { double('Circuitry::PublisherConfig', logger: nil, error_handler: nil, on_async_exit: nil) }
  let(:block) { ->{ } }

  it { is_expected.to be_a Circuitry::Processor }

  it_behaves_like 'an asyncronous processor'

  describe '#process' do
    before do
      allow(subject).to receive(:fork).and_return(pid)
      allow(Process).to receive(:detach)
    end

    let(:pid) { 'pid' }

    it 'forks a process' do
      subject.process
      expect(subject).to have_received(:fork)
    end

    it 'detaches the forked process' do
      subject.process
      expect(Process).to have_received(:detach).with(pid)
    end
  end

  describe '#wait' do
    it 'does nothing' do
      expect { subject.wait }.to_not raise_error
    end
  end
end
