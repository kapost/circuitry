require 'spec_helper'

class TestMiddleware
  attr_accessor :log

  def initialize(log: [])
    self.log = log
  end

  def call(*args)
    log << 'before'
    log.concat(args)
    yield
  ensure
    log << 'after'
  end
end

class TestMiddleware2 < TestMiddleware
end

RSpec.describe Circuitry::Middleware::Chain do
  def entry
    subject.detect { |entry| entry.klass == TestMiddleware }
  end

  describe '#entries' do
    it 'returns an array' do
      expect(subject.entries).to be_an Array
    end
  end

  describe '#add' do
    def add!(log: [])
      subject.add TestMiddleware, log: log
    end

    before do
      subject.add TestMiddleware2
    end

    describe 'when the middleware does not exist' do
      it 'adds an entry' do
        expect { add! }.to change { subject.entries.size }.by(1)
      end

      it 'adds it to the end' do
        add!
        expect(entry).to be subject.entries.last
      end

      it 'sets the entry properly' do
        add!
        expect(entry.klass).to be TestMiddleware
        expect(entry.args).to eq [log: []]
      end
    end

    describe 'when the middleware exists' do
      before do
        add!(log: %w[foo])
      end

      it 'replaces the existing entry' do
        expect { add! }.to_not change { subject.entries.size }
      end

      it 'updates the arguments' do
        add!
        expect(subject.entries.last.klass).to be TestMiddleware
        expect(entry.args).to eq [log: []]
      end
    end
  end

  describe '#remove' do
    def remove!
      subject.remove TestMiddleware
    end

    before do
      subject.add TestMiddleware2
    end

    describe 'when the middleware does not exist' do
      it 'does not remove an entry' do
        expect { remove! }.to_not change { subject.entries.size }
      end
    end

    describe 'when the middleware exists' do
      before do
        subject.add TestMiddleware
      end

      it 'removes an entry' do
        expect { remove! }.to change { subject.entries.size }.by(-1)
      end

      it 'removes the correct entry' do
        remove!
        expect(subject.entries.map(&:klass)).to_not include TestMiddleware
      end
    end
  end

  describe '#prepend' do
    def prepend!(log: [])
      subject.prepend TestMiddleware, log: log
    end

    before do
      subject.add TestMiddleware2
    end

    describe 'when the middleware does not exist' do
      it 'adds an entry' do
        expect { prepend! }.to change { subject.entries.size }.by(1)
      end

      it 'adds it to the beginning' do
        prepend!
        expect(entry).to be subject.entries.first
      end

      it 'sets the entry properly' do
        prepend!
        expect(entry.klass).to be TestMiddleware
        expect(entry.args).to eq [log: []]
      end
    end

    describe 'when the middleware exists' do
      before do
        subject.add TestMiddleware, log: %w[foo]
      end

      it 'replaces the existing entry' do
        expect { prepend! }.to_not change { subject.entries.size }
      end

      it 'moves it to the beginning' do
        prepend!
        expect(entry).to be subject.entries.first
      end

      it 'updates the arguments' do
        prepend!
        expect(entry.klass).to be TestMiddleware
        expect(entry.args).to eq [log: []]
      end
    end
  end

  describe '#insert_before' do
    def insert!(log: [])
      subject.insert_before TestMiddleware2, TestMiddleware, log: log
    end

    describe 'when the new middleware does not exist' do
      shared_examples_for 'an added entry' do
        it 'adds an entry' do
          expect { insert! }.to change { subject.entries.size }.by(1)
        end

        it 'adds it to the beginning' do
          insert!
          expect(entry).to be subject.entries.first
        end

        it 'sets the entry properly' do
          insert!
          expect(entry.klass).to be TestMiddleware
          expect(entry.args).to eq [log: []]
        end
      end

      describe 'when the old middleware does not exist' do
        it_behaves_like 'an added entry'
      end

      describe 'when the old middleware exists' do
        before do
          subject.add TestMiddleware2
        end

        it_behaves_like 'an added entry'
      end
    end

    describe 'when the new middleware exists' do
      before do
        subject.add TestMiddleware, log: %w[foo]
      end

      shared_examples_for 'a replaced entry' do
        it 'replaces the existing entry' do
          expect { insert! }.to_not change { subject.entries.size }
        end

        it 'adds it to the beginning' do
          insert!
          expect(entry).to be subject.entries.first
        end

        it 'updates the arguments' do
          insert!
          expect(entry.klass).to be TestMiddleware
          expect(entry.args).to eq [log: []]
        end
      end

      describe 'when the old middleware does not exist' do
        it_behaves_like 'a replaced entry'
      end

      describe 'when the old middleware exists' do
        before do
          subject.prepend TestMiddleware2
        end

        it_behaves_like 'a replaced entry'
      end
    end
  end

  describe '#insert_after' do
    def insert!(log: [])
      subject.insert_after TestMiddleware2, TestMiddleware, log: log
    end

    describe 'when the new middleware does not exist' do
      shared_examples_for 'an added entry' do
        it 'adds an entry' do
          expect { insert! }.to change { subject.entries.size }.by(1)
        end

        it 'adds it to the end' do
          insert!
          expect(entry).to be subject.entries.last
        end

        it 'sets the entry properly' do
          insert!
          expect(entry.klass).to be TestMiddleware
          expect(entry.args).to eq [log: []]
        end
      end

      describe 'when the old middleware does not exist' do
        it_behaves_like 'an added entry'
      end

      describe 'when the old middleware exists' do
        before do
          subject.add TestMiddleware2
        end

        it_behaves_like 'an added entry'
      end
    end

    describe 'when the new middleware exists' do
      before do
        subject.add TestMiddleware, log: %w[foo]
      end

      shared_examples_for 'a replaced entry' do
        it 'replaces the existing entry' do
          expect { insert! }.to_not change { subject.entries.size }
        end

        it 'adds it to the end' do
          insert!
          expect(entry).to be subject.entries.last
        end

        it 'updates the arguments' do
          insert!
          expect(entry.klass).to be TestMiddleware
          expect(entry.args).to eq [log: []]
        end
      end

      describe 'when the old middleware does not exist' do
        it_behaves_like 'a replaced entry'
      end

      describe 'when the old middleware exists' do
        before do
          subject.add TestMiddleware2
        end

        it_behaves_like 'a replaced entry'
      end
    end
  end

  describe '#exists?' do
    describe 'when the middleware does not exist' do
      it 'returns false' do
        expect(subject.exists?(TestMiddleware)).to be false
      end
    end

    describe 'when the middleware exists' do
      before do
        subject.add TestMiddleware
      end

      it 'returns true' do
        expect(subject.exists?(TestMiddleware)).to be true
      end
    end
  end

  describe '#build' do
    let(:chain) { subject.build }

    before do
      subject.add TestMiddleware, log: %w[foo]
      subject.add TestMiddleware2, log: %w[bar]
    end

    it 'returns an array of instantiated entries' do
      expect(chain[0]).to be_a TestMiddleware
      expect(chain[0].log).to eq %w[foo]

      expect(chain[1]).to be_a TestMiddleware2
      expect(chain[1].log).to eq %w[bar]
    end
  end

  describe '#clear' do
    before do
      subject.add TestMiddleware
      subject.add TestMiddleware2
    end

    it 'removes all entries' do
      expect { subject.clear }.to change { subject.entries.size }.to(0)
    end
  end

  describe '#invoke' do
    def invoke!
      subject.invoke('topic', 'message', &block)
    end

    before do
      subject.add TestMiddleware, log: log1
      subject.add TestMiddleware2, log: log2
    end

    let(:log1) { [] }
    let(:log2) { [] }
    let(:block) { ->{ processor.process } }
    let(:processor) { double('Object', process: true) }

    it 'runs through the first middleware' do
      expect { invoke! }.to change { log1 }.to(%w[before topic message after])
    end

    it 'runs through the last middleware' do
      expect { invoke! }.to change { log2 }.to(%w[before topic message after])
    end

    it 'runs the block' do
      invoke!
      expect(processor).to have_received(:process)
    end
  end
end
