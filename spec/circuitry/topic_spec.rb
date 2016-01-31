require 'spec_helper'

RSpec.describe Circuitry::Topic, type: :model do
  subject { described_class.new(arn) }

  let(:arn) { 'arn:aws:sqs:us-east-1:123456789012:some-topic-name' }

  describe '.find' do
    subject { described_class }

    before do
      allow_any_instance_of(Circuitry::Topic::Finder).to receive(:find).and_return(double('Topic', topic_arn: arn))
    end

    it 'returns a queue object' do
      expect(subject.find('queue_name')).to be_instance_of(Circuitry::Topic)
    end
  end

  describe '#arn' do
    it 'returns the ARN' do
      expect(subject.arn).to eq arn
    end
  end

  describe '#name' do
    it 'returns the last section of the ARN' do
      expect(subject.name).to eq 'some-topic-name'
    end
  end

  describe '#==' do
    it 'returns true for two equal topics' do
      expect(subject).to eq subject.dup
    end

    it 'returns false for unequal topics' do
      other_object = described_class.new(arn.reverse)
      expect(subject).to_not eq other_object
    end

    it 'returns false for different objects with the same ARN' do
      other_class = Struct.new(:arn)
      expect(subject).to_not eq other_class.new(arn)
    end
  end

  describe '#hash' do
    it 'returns true for two equal topics' do
      expect(subject.hash).to eq subject.dup.hash
    end

    it 'returns false for unequal topics' do
      other_object = described_class.new(arn.reverse)
      expect(subject.hash).to_not eq other_object.hash
    end

    it 'returns false for different objects with the same ARN' do
      other_class = Struct.new(:arn)
      expect(subject.hash).to_not eq other_class.new(arn).hash
    end
  end
end
