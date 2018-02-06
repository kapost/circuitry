require 'spec_helper'

processor_class = Class.new(Circuitry::Processor) do
  def process
    block.call
  end

  def wait
    # noop
  end
end

incomplete_processor_class = Class.new(Circuitry::Processor)

RSpec.describe Circuitry::Processor, type: :model do
  subject { processor_class.new(config, &block) }

  let(:config) { double('Circuitry::PublisherConfig', logger: nil, error_handler: nil, on_async_exit: nil) }
  let(:block) { ->{ } }

  describe '#process' do
    describe 'when the class has defined process' do
      it 'raises an error' do
        expect { subject.process }.to_not raise_error
      end
    end

    describe 'when the class has not defined process' do
      subject { incomplete_processor_class.new(config, &block) }

      it 'raises an error' do
        expect { subject.process }.to raise_error(NotImplementedError)
      end
    end
  end

  describe '#safely_process' do
    def process
      subject.send(:safely_process, &block)
    end

    describe 'when the block raises an error' do
      let(:block) { ->{ raise StandardError } }

      before do
        allow(config.logger).to receive(:error)
      end

      it 'does not re-raise the error' do
        expect { process }.to_not raise_error
      end

      it 'logs an error' do
        process
        expect(config.logger).to have_received(:error)
      end

      describe 'when an error handler is defined' do
        let(:error_handler) { double('Proc', call: true) }

        before do
          allow(config).to receive(:error_handler).and_return(error_handler)
        end

        it 'handles the error' do
          process
          expect(config.error_handler).to have_received(:call)
        end
      end

      describe 'when an error handler is not defined' do
        let(:error_handler) { nil }

        before do
          allow_message_expectations_on_nil
          allow(config).to receive(:error_handler).and_return(error_handler)
          allow(error_handler).to receive(:call)
        end

        it 'does not handle the error' do
          process
          expect(config.error_handler).to_not have_received(:call)
        end
      end
    end

    describe 'when the block does not raise an error' do
      it 'does not log an error' do
        expect(config.logger).to_not receive(:error)
        process
      end

      it 'does not handle an error' do
        allow_message_expectations_on_nil
        expect(config.error_handler).to_not receive(:call)
        process
      end
    end
  end

  describe '#wait' do
    describe 'when the class has defined wait' do
      it 'does not raise an error' do
        expect { subject.wait }.to_not raise_error
      end
    end

    describe 'when the class has not defined wait' do
      subject { incomplete_processor_class.new(config, &block) }

      it 'raises an error' do
        expect { subject.wait }.to raise_error(NotImplementedError)
      end
    end
  end
end
