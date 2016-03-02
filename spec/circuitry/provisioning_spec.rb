require 'spec_helper'

RSpec.describe Circuitry::Provisioning do
  subject { described_class }

  describe '.provision' do
    before do
      allow(Circuitry::Provisioning::Provisioner).to receive(:new).with(logger).and_return(provisioner)
    end

    let(:logger) { double('Logger') }
    let(:provisioner) { double('Provisioning::Provisioner', run: true) }

    it 'delegates to provisioner' do
      subject.provision(logger: logger)
      expect(provisioner).to have_received(:run)
    end
  end
end
