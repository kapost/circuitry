require 'spec_helper'

RSpec.describe Circuitry::Processors::Threader, type: :model do
  subject { described_class.new(config, &block) }

  let(:config) { double('Circuitry::PublisherConfig', logger: nil, error_handler: nil, on_async_exit: nil) }
  let(:block) { ->{ } }

  it { is_expected.to be_a Circuitry::Processor }

  it_behaves_like 'an asyncronous processor'

  describe '#process' do
    before do
      allow(Thread).to receive(:new).and_return(thread)
    end

    let(:thread) { double('Thread', join: true) }

    it 'wraps the block in a thread' do
      subject.process
      expect(Thread).to have_received(:new).with(no_args, &block)
    end
  end

  describe '#wait' do
    before do
      allow(Thread).to receive(:new).and_return(thread)
    end

    let(:thread) { double('Thread', join: true) }

    it 'joins the thread' do
      subject.wait
      expect(thread).to have_received(:join)
    end
  end
end
