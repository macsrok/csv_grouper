# frozen_string_literal: true

require "spec_helper"
require "csv_grouping/column_resolver"

RSpec.describe CsvGrouping::ColumnResolver do
  let(:headers) { %w[FirstName workEmail email2 Phone mobilePhone Zip] }

  it "infers email and phone columns by default" do
    result = described_class.resolve(
      headers: headers,
      email_column: nil,
      phone_column: nil,
      infer_column_names: true
    )

    expect(result.email_columns).to eq(%w[workEmail email2])
    expect(result.phone_columns).to eq(%w[Phone mobilePhone])
  end

  it "uses explicit columns instead of inferred columns when inference is disabled" do
    result = described_class.resolve(
      headers: headers,
      email_column: "workEmail",
      phone_column: "mobilePhone",
      infer_column_names: false
    )

    expect(result.email_columns).to eq(["workEmail"])
    expect(result.phone_columns).to eq(["mobilePhone"])
  end

  it "combines explicit and inferred columns when inference is enabled" do
    result = described_class.resolve(
      headers: headers,
      email_column: "FirstName",
      phone_column: "Zip",
      infer_column_names: true
    )

    expect(result.email_columns).to eq(%w[FirstName workEmail email2])
    expect(result.phone_columns).to eq(%w[Zip Phone mobilePhone])
  end

  it "raises a clear error when an explicit email column is missing" do
    expect do
      described_class.resolve(
        headers: headers,
        email_column: "missingEmail",
        phone_column: nil,
        infer_column_names: false
      )
    end.to raise_error(
      CsvGrouping::ColumnResolver::UnknownColumnError,
      /email column "missingEmail" was not found/
    )
  end

  it "raises a clear error when an explicit phone column is missing" do
    expect do
      described_class.resolve(
        headers: headers,
        email_column: nil,
        phone_column: "missingPhone",
        infer_column_names: false
      )
    end.to raise_error(
      CsvGrouping::ColumnResolver::UnknownColumnError,
      /phone column "missingPhone" was not found/
    )
  end
end
