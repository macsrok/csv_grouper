# frozen_string_literal: true

require "spec_helper"
require "csv_grouping/cli_options"

RSpec.describe CsvGrouping::CliOptions do
  subject(:options) { described_class.parse(argv) }

  context "with required arguments" do
    let(:argv) { %w[--input data/input.csv --matcher same_email] }

    it "parses defaults" do
      expect(options.input_path).to eq("data/input.csv")
      expect(options.matcher).to eq("same_email")
      expect(options.output_dir).to be_nil
      expect(options.email_column).to be_nil
      expect(options.phone_column).to be_nil
      expect(options.infer_column_names).to be_nil
    end
  end

  context "with optional arguments" do
    let(:argv) do
      %w[
        --input data/input.csv
        --matcher same_phone
        --output-dir tmp/results
        --email-column workEmail
        --phone-column mobilePhone
        --infer-column-names false
      ]
    end

    it "parses provided values" do
      expect(options.output_dir).to eq("tmp/results")
      expect(options.email_column).to eq("workEmail")
      expect(options.phone_column).to eq("mobilePhone")
      expect(options.infer_column_names).to be(false)
    end
  end

  context "with underscore option aliases" do
    let(:argv) do
      %w[
        --input data/input.csv
        --matcher same_phone
        --output_dir tmp/results
        --phone_column mobilePhone
      ]
    end

    it "accepts underscore aliases from the challenge example" do
      expect(options.output_dir).to eq("tmp/results")
      expect(options.phone_column).to eq("mobilePhone")
    end
  end

  context "with an invalid matcher" do
    let(:argv) { %w[--input data/input.csv --matcher same_name] }

    it "raises a clear validation error" do
      expect { options }.to raise_error(
        CsvGrouping::CliOptions::ValidationError,
        /matcher must be one of same_email, same_phone, same_email_or_phone/
      )
    end
  end

  context "without input" do
    let(:argv) { %w[--matcher same_email] }

    it "raises a clear validation error" do
      expect { options }.to raise_error(CsvGrouping::CliOptions::ValidationError, /input is required/)
    end
  end
end
