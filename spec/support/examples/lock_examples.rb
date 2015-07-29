RSpec.shared_examples_for 'a lock' do
  it { is_expected.to be_a Circuitry::Locks::Base }

  describe '#soft_lock' do
    let(:id) { SecureRandom.hex(100) }
    let(:now) { Time.now }

    before do
      allow(Time).to receive(:now).and_return(now)
    end

    describe 'when the id is not locked' do
      it 'returns true' do
        expect(subject.soft_lock(id)).to be true
      end

      it 'locks the message id for the soft ttl duration' do
        subject.soft_lock(id)
        allow(Time).to receive(:now).and_return(now + soft_ttl - 1)
        expect(subject.soft_lock(id)).to be false
      end

      it 'unlocks the message id after the soft ttl duration' do
        subject.soft_lock(id)
        allow(Time).to receive(:now).and_return(now + soft_ttl)
        expect(subject.soft_lock(id)).to be true
      end
    end

    describe 'when the id is locked' do
      before do
        subject.soft_lock(id)
      end

      it 'returns false' do
        expect(subject.soft_lock(id)).to be false
      end

      it 'does not change the existing lock' do
        allow(Time).to receive(:now).and_return(now + soft_ttl - 1)
        expect(subject.soft_lock(id)).to be false
        allow(Time).to receive(:now).and_return(now + soft_ttl)
        expect(subject.soft_lock(id)).to be true
      end
    end
  end

  describe '#hard_lock' do
    let(:id) { SecureRandom.hex(100) }
    let(:now) { Time.now }

    before do
      allow(Time).to receive(:now).and_return(now)
    end

    shared_examples_for 'an overwriting lock' do
      it 'locks the message id for the hard ttl duration' do
        subject.hard_lock(id)
        allow(Time).to receive(:now).and_return(now + hard_ttl - 1)

        expect {
          allow(Time).to receive(:now).and_return(now + hard_ttl)
        }.to change { subject.soft_lock(id) }.from(false).to(true)
      end
    end

    describe 'when the id is not locked' do
      it_behaves_like 'an overwriting lock'
    end

    describe 'when the id is locked' do
      before { subject.soft_lock(id) }
      it_behaves_like 'an overwriting lock'
    end
  end

  describe '#lock' do
    let(:id) { SecureRandom.hex(100) }

    before do
      subject.hard_lock(id)
    end

    it 'deletes the lock' do
      subject.unlock(id)
      expect(subject.soft_lock(id)).to be true
    end
  end
end
