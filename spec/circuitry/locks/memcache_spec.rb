require 'spec_helper'
require 'securerandom'

RSpec.describe Circuitry::Locks::Memcache, type: :model do
  subject { described_class.new(soft_ttl: soft_ttl, hard_ttl: hard_ttl, client: client) }

  let(:soft_ttl) { 30 }
  let(:hard_ttl) { 60 }
  let(:client) { MemcacheMock.new }

  before do
    client.flush
  end

  # TODO: the `memcache_mock` gem does not support `tll` or the `add` method
  # it_behaves_like 'a lock'

  describe '.new' do
    subject { described_class }

    describe 'when client is provided' do
      let(:options) { { soft_ttl: soft_ttl, hard_ttl: hard_ttl, client: client } }

      it 'does not create a new client' do
        expect(Dalli::Client).to_not receive(:new)
        subject.new(options)
      end
    end

    describe 'when client is not provided' do
      let(:options) { { soft_ttl: soft_ttl, hard_ttl: hard_ttl, host: host } }
      let(:host) { 'localhost:11211' }

      it 'creates a new client' do
        expect(Dalli::Client).to receive(:new).with(host, options)
        subject.new(options)
      end
    end
  end
end
