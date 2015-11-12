require 'spec_helper'

RSpec.describe Circuitry::Message, type: :model do
  subject { described_class.new(sqs_message) }

  let(:sqs_message) { double(message_id: id, receipt_handle: handle, body: context.to_json) }

  let(:id) { '123' }
  let(:handle) { '456' }
  let(:body) { 'foo' }
  let(:arn) { 'arn:aws:sns:us-east-1:123456789012:test-event-task-changed' }
  let(:context) { { 'Message' => body.to_json, 'TopicArn' => arn } }

  its(:sqs_message) { is_expected.to eq sqs_message }
  its(:id) { is_expected.to eq id }
  its(:context) { is_expected.to eq context }
  its(:body) { is_expected.to eq body }
  its(:topic) { is_expected.to eq Circuitry::Topic.new(arn) }
  its(:receipt_handle) { is_expected.to eq handle }
end
