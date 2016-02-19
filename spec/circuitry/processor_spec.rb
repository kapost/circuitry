require 'spec_helper'

processor_class = Class.new do
  include Circuitry::Processor

  def process(&block)
    block.call
  end

  def flush
    pool.clear
  end
end

incomplete_processor_class = Class.new do
  include Circuitry::Processor
end

RSpec.describe Circuitry::Processor, type: :model do
  subject { processor_class.new }

  describe '.process' do
    let(:block) { ->{ } }

    describe 'when the class has defined process' do
      it 'raises an error' do
        expect { subject.process(&block) }.to_not raise_error
      end
    end

    describe 'when the class has not defined process' do
      subject { incomplete_processor_class.new }

      it 'raises an error' do
        expect { subject.process(&block) }.to raise_error(NotImplementedError)
      end
    end
  end

  describe '.safely_process' do
    def process
      subject.send(:safely_process, &block)
    end

    describe 'when the block raises an error' do
      let(:block) { ->{ raise StandardError } }

      before do
        allow(Circuitry.subscriber_config.logger).to receive(:error)
      end

      it 'does not re-raise the error' do
        expect { process }.to_not raise_error
      end

      it 'logs an error' do
        process
        expect(Circuitry.subscriber_config.logger).to have_received(:error)
      end

      describe 'when an error handler is defined' do
        let(:error_handler) { double('Proc', call: true) }

        before do
          allow(Circuitry.subscriber_config).to receive(:error_handler).and_return(error_handler)
        end

        it 'handles the error' do
          process
          expect(Circuitry.subscriber_config.error_handler).to have_received(:call)
        end
      end

      describe 'when an error handler is not defined' do
        let(:error_handler) { nil }

        before do
          allow_message_expectations_on_nil
          allow(Circuitry.subscriber_config).to receive(:error_handler).and_return(error_handler)
          allow(error_handler).to receive(:call)
        end

        it 'does not handle the error' do
          process
          expect(Circuitry.subscriber_config.error_handler).to_not have_received(:call)
        end
      end
    end

    describe 'when the block does not raise an error' do
      let(:block) { ->{ } }

      it 'does not log an error' do
        expect(Circuitry.subscriber_config.logger).to_not receive(:error)
        process
      end

      it 'does not handle an error' do
        allow_message_expectations_on_nil
        expect(Circuitry.subscriber_config.error_handler).to_not receive(:call)
        process
      end
    end
  end

  describe '#flush' do
    describe 'when the class has defined flush' do
      it 'does not raise an error' do
        expect { subject.flush }.to_not raise_error
      end
    end

    describe 'when the class has not defined flush' do
      subject { incomplete_processor_class.new }

      it 'raises an error' do
        expect { subject.flush }.to raise_error(NotImplementedError)
      end
    end
  end
end
