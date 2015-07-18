RSpec.shared_examples_for 'a lock' do
  it { is_expected.to be_a Circuitry::Locks::Base }

  before do
    subject.reap
  end

  describe '#soft_lock' do
    let(:id) { SecureRandom.hex(100) }

    it 'locks the message id' do
      expect { subject.soft_lock(id) }.to change { subject.locked?(id) }.from(false).to(true)
    end

    it 'locks the message id for the soft ttl duration' do
      now = Time.now
      allow(Time).to receive(:now).and_return(now)

      subject.soft_lock(id)

      allow(Time).to receive(:now).and_return(now + soft_ttl)
      expect(subject).to be_locked(id)
    end

    it 'unlocks the message id after the soft ttl duration' do
      now = Time.now
      allow(Time).to receive(:now).and_return(now)

      subject.soft_lock(id)

      allow(Time).to receive(:now).and_return(now + soft_ttl + 1)
      expect(subject).to_not be_locked(id)
    end
  end

  describe '#hard_lock' do
    let(:id) { SecureRandom.hex(100) }

    it 'locks the message id' do
      expect { subject.hard_lock(id) }.to change { subject.locked?(id) }.from(false).to(true)
    end

    it 'locks the message id for the hard ttl duration' do
      now = Time.now
      allow(Time).to receive(:now).and_return(now)

      subject.hard_lock(id)

      allow(Time).to receive(:now).and_return(now + hard_ttl)
      expect(subject).to be_locked(id)
    end

    it 'unlocks the message id after the hard ttl duration' do
      now = Time.now
      allow(Time).to receive(:now).and_return(now)

      subject.hard_lock(id)

      allow(Time).to receive(:now).and_return(now + hard_ttl + 1)
      expect(subject).to_not be_locked(id)
    end
  end

  describe '#locked?' do
    let(:id) { SecureRandom.hex(100) }

    describe 'when the id is locked' do
      it 'returns true' do
        subject.soft_lock(id)
        expect(subject).to be_locked(id)
      end
    end

    describe 'when the id is not locked' do
      it 'returns false' do
        expect(subject).to_not be_locked(id)
      end
    end
  end

  describe '#reap' do
    let(:id) { SecureRandom.hex(100) }

    it 'deletes expired locks' do
      now = Time.now
      allow(Time).to receive(:now).and_return(now)

      subject.soft_lock(id)

      expect {
        allow(Time).to receive(:now).and_return(now + soft_ttl + 1)
        subject.reap
      }.to change { subject.locked?(id) }.from(true).to(false)
    end

    it 'does not delete unexpired locks' do
      now = Time.now
      allow(Time).to receive(:now).and_return(now)

      subject.soft_lock(id)

      expect {
        allow(Time).to receive(:now).and_return(now + soft_ttl)
        subject.reap
      }.to_not change { subject.locked?(id) }.from(true)
    end
  end
end
