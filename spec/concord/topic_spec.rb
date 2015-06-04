require 'spec_helper'

RSpec.describe Concord::Topic, type: :model do
  subject { described_class.new(arn) }

  let(:arn) { 'arn:aws:sqs:us-east-1:123456789012:some-topic-name' }

  describe '#arn' do
    it 'returns the ARN' do
      expect(subject.arn).to eq arn
    end
  end
end
