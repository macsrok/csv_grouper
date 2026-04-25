# frozen_string_literal: true

require "fileutils"
require "open3"
require "tmpdir"

require "spec_helper"

RSpec.describe "group_records wrapper" do
  subject(:result) { Open3.capture3(environment, wrapper_path, *arguments) }

  let(:root) { File.expand_path("..", __dir__) }
  let(:wrapper_path) { File.join(root, "group_records") }
  let(:tmpdir) { Dir.mktmpdir }
  let(:bin_dir) { File.join(tmpdir, "bin") }
  let(:environment) { { "PATH" => "#{bin_dir}:#{ENV.fetch('PATH')}" } }

  before do
    FileUtils.mkdir_p(bin_dir)
  end

  after do
    FileUtils.remove_entry(tmpdir) if File.directory?(tmpdir)
  end

  context "with --help" do
    let(:arguments) { ["--help"] }

    it "prints help without checking Ruby or Bundler" do
      expect(result[2].exitstatus).to eq(0)
      expect(result[0]).to include("Usage: ./group_records --input PATH --matcher MATCHER")
      expect(result[0]).to include("same_email_or_phone")
    end
  end

  context "without input" do
    let(:arguments) { %w[--matcher same_email] }

    it "prints a wrapper-level error" do
      expect(result[2].exitstatus).to eq(1)
      expect(result[1]).to include("Error: --input is required")
    end
  end

  context "without matcher" do
    let(:arguments) { %w[--input data/input1.csv] }

    it "prints a wrapper-level error" do
      expect(result[2].exitstatus).to eq(1)
      expect(result[1]).to include("Error: --matcher is required")
    end
  end

  context "when Ruby is not version 4" do
    let(:arguments) { %w[--input data/input1.csv --matcher same_email] }

    before do
      write_executable("ruby", <<~SH)
        #!/usr/bin/env bash
        if [[ "$1" == "-e" ]]; then
          exit 1
        fi
        exit 0
      SH
    end

    it "prints a Ruby version error" do
      expect(result[2].exitstatus).to eq(1)
      expect(result[1]).to include("Error: Ruby 4 is required")
    end
  end

  context "when bundle check passes" do
    let(:arguments) { %w[--input data/input1.csv --matcher same_email --output-dir tmp/out] }
    let(:log_path) { File.join(tmpdir, "commands.log") }

    before do
      write_executable("ruby", <<~SH)
        #!/usr/bin/env bash
        if [[ "$1" == "-e" ]]; then
          exit 0
        fi
        echo "ruby $*" >> "#{log_path}"
        exit 0
      SH
      write_executable("bundle", <<~SH)
        #!/usr/bin/env bash
        echo "bundle $*" >> "#{log_path}"
        exit 0
      SH
    end

    it "runs bundle check and delegates all arguments to Ruby" do
      expect(result[2].exitstatus).to eq(0)
      expect(File.read(log_path)).to include("bundle check")
      expect(File.read(log_path)).to include("ruby -Ilib exe/group_records --input data/input1.csv --matcher same_email --output-dir tmp/out")
    end
  end

  context "when bundle check fails" do
    let(:arguments) { %w[--input data/input1.csv --matcher same_email] }
    let(:log_path) { File.join(tmpdir, "commands.log") }

    before do
      write_executable("ruby", <<~SH)
        #!/usr/bin/env bash
        if [[ "$1" == "-e" ]]; then
          exit 0
        fi
        echo "ruby $*" >> "#{log_path}"
        exit 0
      SH
      write_executable("bundle", <<~SH)
        #!/usr/bin/env bash
        echo "bundle $*" >> "#{log_path}"
        if [[ "$1" == "check" ]]; then
          exit 1
        fi
        exit 0
      SH
    end

    it "runs bundle install before delegating to Ruby" do
      expect(result[2].exitstatus).to eq(0)
      expect(File.read(log_path)).to include("bundle check")
      expect(File.read(log_path)).to include("bundle install")
      expect(File.read(log_path)).to include("ruby -Ilib exe/group_records --input data/input1.csv --matcher same_email")
    end
  end

  def write_executable(name, content)
    path = File.join(bin_dir, name)
    File.write(path, content)
    FileUtils.chmod("+x", path)
  end
end
