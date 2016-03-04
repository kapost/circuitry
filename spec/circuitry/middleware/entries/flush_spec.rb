require 'spec_helper'

RSpec.describe Circuitry::Middleware::Entries::Flush do
  subject { described_class.new(options) }

  let(:options) { {} }

  describe '#call' do
    def call
      subject.call('topic', 'message', &block)
    end

    describe 'when processing succeeds' do
      let(:block) { ->{} }

      it 'flushes' do
        expect(Circuitry).to receive(:flush)
        call
      end
    end

    describe 'when processing fails' do
      let(:block) { ->{ raise StandardError, 'test failure' } }

      it 'flushes' do
        expect(Circuitry).to receive(:flush)
        call rescue nil
      end

      it 'raises the error' do
        expect { call }.to raise_error
      end
    end
  end
end
