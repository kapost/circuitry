RSpec.shared_examples_for 'a validated setting' do |permitted_values, setting_name|
  def set(value)
    subject.public_send(:"#{setting}=", value)
  end

  def get
    subject.public_send(setting)
  end

  let(:setting) { setting_name }

  permitted_values.each do |value|
    describe "with valid value #{value}" do
      it 'does not raise an error' do
        expect { set(value) }.to_not raise_error
      end

      it 'changes the config value' do
        set(value)
        expect(get).to eq value
      end
    end
  end

  describe 'with invalid value' do
    it 'raises an error' do
      expect { set(:fake) }.to raise_error ArgumentError
    end

    it 'does not change the config value' do
      expect { set(:fake) rescue nil }.to_not change { get }
    end
  end
end
