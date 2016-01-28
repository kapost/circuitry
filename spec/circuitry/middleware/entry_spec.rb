require 'spec_helper'

class TestEntry
  attr_accessor :value

  def initialize(value)
    self.value = value
  end
end

RSpec.describe Circuitry::Middleware::Entry do
  subject { described_class.new(klass, value) }

  let(:klass) { TestEntry }
  let(:value) { 'foo' }

  its(:klass) { is_expected.to be klass }
  its(:args) { is_expected.to eq [value] }

  describe '#build' do
    it 'returns returns an instance with args passed in' do
      instance = subject.build

      expect(instance).to be_a TestEntry
      expect(instance.value).to eq value
    end
  end
end
