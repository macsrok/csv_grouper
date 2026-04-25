# frozen_string_literal: true

require "spec_helper"
require "csv_grouping/column_resolver"
require "csv_grouping/errors"

RSpec.describe CsvGrouping::ColumnResolver do
  subject(:result) do
    described_class.resolve(
      headers: headers,
      email_column: email_column,
      phone_column: phone_column,
      infer_column_names: infer_column_names
    )
  end

  let(:headers) { %w[FirstName workEmail email2 Phone mobilePhone Zip] }
  let(:email_column) { nil }
  let(:phone_column) { nil }
  let(:infer_column_names) { true }

  context "with inferred columns" do
    it "infers email and phone columns by default" do
      expect(result.email_columns).to eq(%w[workEmail email2])
      expect(result.phone_columns).to eq(%w[Phone mobilePhone])
    end
  end

  context "with explicit columns and inference disabled" do
    let(:email_column) { "workEmail" }
    let(:phone_column) { "mobilePhone" }
    let(:infer_column_names) { false }

    it "uses explicit columns instead of inferred columns" do
      expect(result.email_columns).to eq(["workEmail"])
      expect(result.phone_columns).to eq(["mobilePhone"])
    end
  end

  context "with explicit columns and inference enabled" do
    let(:email_column) { "FirstName" }
    let(:phone_column) { "Zip" }

    it "combines explicit and inferred columns" do
      expect(result.email_columns).to eq(%w[FirstName workEmail email2])
      expect(result.phone_columns).to eq(%w[Zip Phone mobilePhone])
    end
  end

  context "with a missing explicit email column" do
    let(:email_column) { "missingEmail" }
    let(:infer_column_names) { false }

    it "raises a clear error" do
      expect { result }.to raise_error(
        CsvGrouping::UnknownColumnError,
        /email column "missingEmail" was not found/
      )
    end
  end

  context "with a missing explicit phone column" do
    let(:phone_column) { "missingPhone" }
    let(:infer_column_names) { false }

    it "raises a clear error" do
      expect { result }.to raise_error(
        CsvGrouping::UnknownColumnError,
        /phone column "missingPhone" was not found/
      )
    end
  end
end
