RSpec.shared_examples_for 'an asyncronous processor' do
  context 'when on_async_exit is defined' do
    let(:block) { -> {} }
    let(:on_async_exit) { double('Proc', call: true) }

    before do
      allow(subject).to receive(:fork) { |&block| block.call }
      allow(Process).to receive(:detach)
      allow(config).to receive(:on_async_exit).and_return(on_async_exit)
    end

    it 'calls the proc' do
      subject.process
      subject.wait
      expect(on_async_exit).to have_received(:call)
    end
  end
end
