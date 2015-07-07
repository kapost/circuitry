require 'spec_helper'

processor_class = Class.new do
  include Circuitry::Processor
end

RSpec.describe Circuitry::Processor, type: :model do
  subject { processor_class.new }

  describe '.process' do
    def process
      subject.send(:process, &block)
    end

    describe 'when the block raises an error' do
      let(:block) { ->{ raise StandardError } }

      it 'does not re-raise the error' do
        expect { process }.to_not raise_error
      end

      it 'logs an error' do
        expect(Circuitry.config.logger).to receive(:error)
        process
      end

      describe 'when an error handler is defined' do
        let(:error_handler) { double('Proc', call: true) }

        before do
          allow(Circuitry.config).to receive(:error_handler).and_return(error_handler)
        end

        it 'handles the error' do
          process
          expect(Circuitry.config.error_handler).to have_received(:call)
        end
      end

      describe 'when an error handler is not defined' do
        let(:error_handler) { nil }

        before do
          allow(Circuitry.config).to receive(:error_handler).and_return(error_handler)
          allow(error_handler).to receive(:call)
        end

        it 'does not handle the error' do
          process
          expect(Circuitry.config.error_handler).to_not have_received(:call)
        end
      end
    end

    describe 'when the block does not raise an error' do
      let(:block) { ->{ } }

      it 'does not log an error' do
        expect(Circuitry.config.logger).to_not receive(:error)
        process
      end

      it 'does not handle an error' do
        expect(Circuitry.config.error_handler).to_not receive(:call)
        process
      end
    end
  end
end
