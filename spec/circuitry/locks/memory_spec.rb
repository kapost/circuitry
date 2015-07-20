require 'spec_helper'

RSpec.describe Circuitry::Locks::Memory, type: :model do
  subject { described_class.new(soft_ttl: soft_ttl, hard_ttl: hard_ttl) }

  let(:soft_ttl) { 30 }
  let(:hard_ttl) { 60 }

  before do
    described_class.store.clear
  end

  it_behaves_like 'a lock'
end
