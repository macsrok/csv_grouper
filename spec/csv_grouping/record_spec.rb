# frozen_string_literal: true

require "spec_helper"
require "csv_grouping/record"

RSpec.describe CsvGrouping::Record do
  subject(:record) do
    described_class.new(row, email_columns: email_columns, phone_columns: phone_columns)
  end

  let(:row) do
    { "Email" => " USER@example.com ", "Phone" => "(555) 123-4567", "OtherPhone" => "555.987.6543" }
  end
  let(:email_columns) { ["Email"] }
  let(:phone_columns) { %w[Phone OtherPhone] }

  it "keeps the original row available" do
    expect(record.row).to include("Email" => " USER@example.com ")
  end

  it "normalizes email values at creation time" do
    expect(record.email_keys).to eq(["email:user@example.com"])
  end

  it "normalizes phone values at creation time" do
    expect(record.phone_keys).to eq(%w[phone:5551234567 phone:5559876543])
  end

  context "with blank values" do
    let(:row) { { "Email" => " ", "Phone" => nil } }
    let(:phone_columns) { ["Phone"] }

    it "ignores blank normalized values" do
      expect(record.email_keys).to eq([])
      expect(record.phone_keys).to eq([])
    end
  end

  describe "#keys_for" do
    context "with same_email" do
      it "returns email keys" do
        expect(record.keys_for("same_email")).to eq(["email:user@example.com"])
      end
    end

    context "with same_phone" do
      it "returns phone keys" do
        expect(record.keys_for("same_phone")).to eq(%w[phone:5551234567 phone:5559876543])
      end
    end

    context "with same_email_or_phone" do
      it "returns email and phone keys" do
        expect(record.keys_for("same_email_or_phone")).to eq(
          %w[email:user@example.com phone:5551234567 phone:5559876543]
        )
      end
    end
  end
end
