require 'spec_helper'

RSpec.describe Concord::Message, type: :model do
  subject { described_class.new(raw) }

  let(:raw) do
    {
        'MessageId' => id,
        'ReceiptHandle' => handle,
        'Body' => context.to_json,
    }
  end

  let(:id) { '123' }
  let(:handle) { '456' }
  let(:body) { 'foo' }
  let(:arn) { 'arn:aws:sns:us-east-1:123456789012:test-event-task-changed' }
  let(:context) { { 'Message' => body.to_json, 'TopicArn' => arn } }

  its(:raw) { is_expected.to eq raw }
  its(:id) { is_expected.to eq id }
  its(:context) { is_expected.to eq context }
  its(:body) { is_expected.to eq body }
  its(:topic) { is_expected.to eq Concord::Topic.new(arn) }
  its(:receipt_handle) { is_expected.to eq handle }
end
