# frozen_string_literal: true

require "spec_helper"
require "csv_grouping/record_grouper"

RSpec.describe CsvGrouping::RecordGrouper do
  subject(:grouped) do
    described_class.group(
      described_class::Request.new(
        rows: rows,
        matcher: matcher,
        email_columns: email_columns,
        phone_columns: phone_columns
      )
    )
  end

  let(:email_columns) { ["Email"] }
  let(:phone_columns) { ["Phone"] }
  let(:person_ids) { grouped.map { |row| row["PersonId"] } }

  context "when matching by email" do
    let(:matcher) { "same_email" }
    let(:rows) do
      [
        { "Email" => "USER@example.com", "Phone" => "111" },
        { "Email" => " user@example.com ", "Phone" => "222" },
        { "Email" => "other@example.com", "Phone" => "333" }
      ]
    end

    it "groups rows with the same normalized email" do
      expect(person_ids).to eq(%w[1 1 2])
    end
  end

  context "when matching by phone" do
    let(:matcher) { "same_phone" }
    let(:rows) do
      [
        { "Email" => "a@example.com", "Phone" => "(555) 123-4567" },
        { "Email" => "b@example.com", "Phone" => "555.123.4567" },
        { "Email" => "c@example.com", "Phone" => "4567890123" }
      ]
    end

    it "groups rows with the same normalized phone number" do
      expect(person_ids).to eq(%w[1 1 2])
    end
  end

  context "when matching by email or phone" do
    let(:matcher) { "same_email_or_phone" }

    context "with transitive matches" do
      let(:rows) do
        [
          { "Email" => "a@example.com", "Phone" => "111" },
          { "Email" => "a@example.com", "Phone" => "222" },
          { "Email" => "c@example.com", "Phone" => "222" },
          { "Email" => "d@example.com", "Phone" => "444" }
        ]
      end

      it "groups transitively" do
        expect(person_ids).to eq(%w[1 1 1 2])
      end
    end

    context "with blank matching values" do
      let(:rows) do
        [
          { "Email" => "", "Phone" => "" },
          { "Email" => " ", "Phone" => nil },
          { "Email" => "known@example.com", "Phone" => "" }
        ]
      end

      it "ignores blanks" do
        expect(person_ids).to eq(%w[1 2 3])
      end
    end

    context "with multiple email and phone columns" do
      let(:email_columns) { %w[Email1 Email2] }
      let(:phone_columns) { %w[Phone1 Phone2] }
      let(:rows) do
        [
          { "Email1" => "a@example.com", "Email2" => "", "Phone1" => "111", "Phone2" => "" },
          { "Email1" => "", "Email2" => "a@example.com", "Phone1" => "", "Phone2" => "222" },
          { "Email1" => "", "Email2" => "c@example.com", "Phone1" => "222", "Phone2" => "" }
        ]
      end

      it "uses values from every configured column" do
        expect(person_ids).to eq(%w[1 1 1])
      end
    end
  end
end
