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
  let(:context) { { 'Message' => body.to_json } }

  its(:raw) { is_expected.to eq raw }
  its(:context) { is_expected.to eq context }
  its(:body) { is_expected.to eq body }
  its(:id) { is_expected.to eq id }
  its(:receipt_handle) { is_expected.to eq handle }
end
