require 'spec_helper'

RSpec.describe Circuitry::Processors::Batcher, type: :model do
  subject { described_class.new(config, &block) }

  let(:config) { double('Circuitry::PublisherConfig', logger: nil, error_handler: nil, on_async_exit: nil) }
  let(:block) { -> {} }

  it { is_expected.to be_a Circuitry::Processor }

  describe '#process' do
    it 'does not call the block' do
      expect(block).to_not receive(:call)
      subject.process
    end
  end

  describe '#wait' do
    it 'calls the block' do
      expect(block).to receive(:call)
      subject.wait
    end
  end
end
