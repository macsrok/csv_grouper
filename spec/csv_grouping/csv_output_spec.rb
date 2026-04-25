# frozen_string_literal: true

require "csv"
require "tmpdir"

require "spec_helper"
require "csv_grouping/csv_output"

RSpec.describe CsvGrouping::CsvOutput do
  subject(:result) do
    described_class.write(
      described_class::Request.new(
        options: options,
        headers: headers,
        rows: rows
      )
    )
  end

  let(:options) do
    Struct.new(:input_path, :matcher, :output_dir).new(input_path, matcher, output_dir)
  end
  let(:matcher) { "same_email" }
  let(:headers) { %w[PersonId Name] }
  let(:rows) do
    [
      { "PersonId" => "1", "Name" => "Jane" },
      { "PersonId" => "2", "Name" => "John" }
    ]
  end

  context "with the default output directory" do
    around do |example|
      Dir.mktmpdir do |dir|
        @working_dir = dir
        Dir.chdir(dir) { example.run }
      end
    end

    let(:input_path) { "data/input1.csv" }
    let(:output_dir) { nil }
    let(:expected_path) { File.realpath(File.join(@working_dir, "outputs", "input1_same_email.csv")) }

    it "writes the full CSV under outputs" do
      expect(File.realpath(result.path)).to eq(expected_path)
      expect(CSV.read(result.path, headers: true).map { |row| row["Name"] }).to eq(%w[Jane John])
    end
  end

  context "with a custom output directory" do
    let(:tmpdir) { Dir.mktmpdir }
    let(:input_path) { "/tmp/source.csv" }
    let(:matcher) { "same_phone" }
    let(:output_dir) { File.join(tmpdir, "custom") }

    after do
      FileUtils.remove_entry(tmpdir) if File.directory?(tmpdir)
    end

    it "writes to the custom output directory" do
      expect(result.path).to eq(File.join(output_dir, "source_same_phone.csv"))
      expect(File.exist?(result.path)).to be(true)
    end
  end

  context "with more than 100 data rows" do
    let(:input_path) { "input.csv" }
    let(:matcher) { "same_email_or_phone" }
    let(:output_dir) { Dir.mktmpdir }
    let(:rows) do
      105.times.map do |index|
        { "PersonId" => index.to_s, "Name" => "Name#{index}" }
      end
    end
    let(:preview) { CSV.parse(result.preview) }

    after do
      FileUtils.remove_entry(output_dir) if File.directory?(output_dir)
    end

    it "builds a preview with the header and the last 100 data rows" do
      expect(preview.first).to eq(%w[PersonId Name])
      expect(preview.length).to eq(101)
      expect(preview[1]).to eq(%w[5 Name5])
      expect(preview.last).to eq(%w[104 Name104])
    end
  end
end
