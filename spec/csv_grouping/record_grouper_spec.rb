# frozen_string_literal: true

require "spec_helper"
require "csv_grouping/record_grouper"

RSpec.describe CsvGrouping::RecordGrouper do
  it "groups rows with the same normalized email" do
    rows = [
      { "Email" => "USER@example.com", "Phone" => "111" },
      { "Email" => " user@example.com ", "Phone" => "222" },
      { "Email" => "other@example.com", "Phone" => "333" }
    ]

    grouped = described_class.group(
      rows: rows,
      matcher: "same_email",
      email_columns: ["Email"],
      phone_columns: ["Phone"]
    )

    expect(grouped.map { |row| row["PersonId"] }).to eq(%w[1 1 2])
  end

  it "groups rows with the same normalized phone number" do
    rows = [
      { "Email" => "a@example.com", "Phone" => "(555) 123-4567" },
      { "Email" => "b@example.com", "Phone" => "555.123.4567" },
      { "Email" => "c@example.com", "Phone" => "4567890123" }
    ]

    grouped = described_class.group(
      rows: rows,
      matcher: "same_phone",
      email_columns: ["Email"],
      phone_columns: ["Phone"]
    )

    expect(grouped.map { |row| row["PersonId"] }).to eq(%w[1 1 2])
  end

  it "groups transitively when matching by email or phone" do
    rows = [
      { "Email" => "a@example.com", "Phone" => "111" },
      { "Email" => "a@example.com", "Phone" => "222" },
      { "Email" => "c@example.com", "Phone" => "222" },
      { "Email" => "d@example.com", "Phone" => "444" }
    ]

    grouped = described_class.group(
      rows: rows,
      matcher: "same_email_or_phone",
      email_columns: ["Email"],
      phone_columns: ["Phone"]
    )

    expect(grouped.map { |row| row["PersonId"] }).to eq(%w[1 1 1 2])
  end

  it "ignores blank matching values" do
    rows = [
      { "Email" => "", "Phone" => "" },
      { "Email" => " ", "Phone" => nil },
      { "Email" => "known@example.com", "Phone" => "" }
    ]

    grouped = described_class.group(
      rows: rows,
      matcher: "same_email_or_phone",
      email_columns: ["Email"],
      phone_columns: ["Phone"]
    )

    expect(grouped.map { |row| row["PersonId"] }).to eq(%w[1 2 3])
  end

  it "uses values from multiple columns for the selected matcher" do
    rows = [
      { "Email1" => "a@example.com", "Email2" => "", "Phone1" => "111", "Phone2" => "" },
      { "Email1" => "", "Email2" => "a@example.com", "Phone1" => "", "Phone2" => "222" },
      { "Email1" => "", "Email2" => "c@example.com", "Phone1" => "222", "Phone2" => "" }
    ]

    grouped = described_class.group(
      rows: rows,
      matcher: "same_email_or_phone",
      email_columns: %w[Email1 Email2],
      phone_columns: %w[Phone1 Phone2]
    )

    expect(grouped.map { |row| row["PersonId"] }).to eq(%w[1 1 1])
  end
end
