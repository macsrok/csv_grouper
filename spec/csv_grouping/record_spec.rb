# frozen_string_literal: true

require "spec_helper"
require "csv_grouping/record"

RSpec.describe CsvGrouping::Record do
  subject(:record) do
    described_class.new(
      { "Email" => " USER@example.com ", "Phone" => "(555) 123-4567", "OtherPhone" => "555.987.6543" },
      email_columns: ["Email"],
      phone_columns: %w[Phone OtherPhone]
    )
  end

  it "keeps the original row available" do
    expect(record.row).to include("Email" => " USER@example.com ")
  end

  it "normalizes email values at creation time" do
    expect(record.email_keys).to eq(["email:user@example.com"])
  end

  it "normalizes phone values at creation time" do
    expect(record.phone_keys).to eq(%w[phone:5551234567 phone:5559876543])
  end

  it "ignores blank normalized values" do
    blank_record = described_class.new(
      { "Email" => " ", "Phone" => nil },
      email_columns: ["Email"],
      phone_columns: ["Phone"]
    )

    expect(blank_record.email_keys).to eq([])
    expect(blank_record.phone_keys).to eq([])
  end

  it "returns keys for a matcher" do
    expect(record.keys_for("same_email")).to eq(["email:user@example.com"])
    expect(record.keys_for("same_phone")).to eq(%w[phone:5551234567 phone:5559876543])
    expect(record.keys_for("same_email_or_phone")).to eq(
      %w[email:user@example.com phone:5551234567 phone:5559876543]
    )
  end
end
