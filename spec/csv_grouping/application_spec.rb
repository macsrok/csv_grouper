# frozen_string_literal: true

require "csv"
require "stringio"
require "tmpdir"

require "spec_helper"
require "csv_grouping/application"

RSpec.describe CsvGrouping::Application do
  subject(:status) { described_class.call(argv: argv, stdout: stdout, stderr: stderr) }

  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }
  let(:tmpdir) { Dir.mktmpdir }
  let(:input_path) { File.join(tmpdir, "people.csv") }
  let(:output_dir) { File.join(tmpdir, "grouped") }

  before do
    CSV.open(input_path, "w") do |csv|
      csv << %w[Name Email Phone workEmail mobilePhone]
      csv << ["Jane", "jane@example.com", "(555) 123-4567", "", ""]
      csv << ["Janet", "JANe@example.com", "", "", ""]
      csv << ["John", "john@example.com", "444.123.4567", "", ""]
    end
  end

  after do
    FileUtils.remove_entry(tmpdir) if File.directory?(tmpdir)
  end

  context "with a valid same_email run" do
    let(:argv) do
      [
        "--input", input_path,
        "--matcher", "same_email",
        "--output-dir", output_dir
      ]
    end
    let(:output_path) { File.join(output_dir, "people_same_email.csv") }
    let(:output_rows) { CSV.read(output_path, headers: true) }

    it "writes grouped output and prints a preview" do
      expect(status).to eq(0)
      expect(output_rows.map { |row| row["PersonId"] }).to eq(%w[1 1 2])
      expect(stdout.string).to include("PersonId,Name,Email,Phone,workEmail,mobilePhone")
      expect(stderr.string).to eq("")
    end
  end

  context "with explicit email column override" do
    before do
      CSV.open(input_path, "w") do |csv|
        csv << %w[Name Email workEmail Phone]
        csv << ["Jane", "shared@example.com", "jane@work.com", ""]
        csv << ["Janet", "shared@example.com", "janet@work.com", ""]
      end
    end

    let(:argv) do
      [
        "--input", input_path,
        "--matcher", "same_email",
        "--email-column", "workEmail",
        "--output-dir", output_dir
      ]
    end
    let(:output_rows) { CSV.read(File.join(output_dir, "people_same_email.csv"), headers: true) }

    it "uses only the explicit email column" do
      expect(status).to eq(0)
      expect(output_rows.map { |row| row["PersonId"] }).to eq(%w[1 2])
    end
  end

  context "with explicit email column plus inferred columns enabled" do
    before do
      CSV.open(input_path, "w") do |csv|
        csv << %w[Name Email workEmail Phone]
        csv << ["Jane", "shared@example.com", "jane@work.com", ""]
        csv << ["Janet", "shared@example.com", "janet@work.com", ""]
      end
    end

    let(:argv) do
      [
        "--input", input_path,
        "--matcher", "same_email",
        "--email-column", "workEmail",
        "--infer-column-names", "true",
        "--output-dir", output_dir
      ]
    end
    let(:output_rows) { CSV.read(File.join(output_dir, "people_same_email.csv"), headers: true) }

    it "uses the explicit email column and inferred email columns" do
      expect(status).to eq(0)
      expect(output_rows.map { |row| row["PersonId"] }).to eq(%w[1 1])
    end
  end

  context "with an invalid matcher" do
    let(:argv) { ["--input", input_path, "--matcher", "same_name"] }

    it "returns a nonzero status and writes the error to stderr" do
      expect(status).to eq(1)
      expect(stderr.string).to include("matcher must be one of")
    end
  end
end
