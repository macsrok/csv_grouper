# frozen_string_literal: true

require "csv"
require "fileutils"

module CsvGrouping
  class CsvOutput
    Result = Struct.new(:path, :preview, keyword_init: true)

    def self.write(input_path:, matcher:, headers:, rows:, output_dir:)
      new(input_path, matcher, headers, rows, output_dir).write
    end

    def initialize(input_path, matcher, headers, rows, output_dir)
      @input_path = input_path
      @matcher = matcher
      @headers = headers
      @rows = rows
      @output_dir = output_dir
    end

    def write
      FileUtils.mkdir_p(resolved_output_dir)
      CSV.open(path, "w", write_headers: true, headers: @headers) do |csv|
        @rows.each { |row| csv << @headers.map { |header| row[header] } }
      end

      Result.new(path: path, preview: preview)
    end

    private

    def path
      @path ||= File.join(resolved_output_dir, "#{input_basename}_#{@matcher}.csv")
    end

    def resolved_output_dir
      @resolved_output_dir ||= File.expand_path(@output_dir || "outputs")
    end

    def input_basename
      File.basename(@input_path, File.extname(@input_path))
    end

    def preview
      CSV.generate do |csv|
        csv << @headers
        @rows.last(100).each { |row| csv << @headers.map { |header| row[header] } }
      end
    end
  end
end
