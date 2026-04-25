# frozen_string_literal: true

require "csv"
require "fileutils"

module CsvGrouping
  # Writes the complete grouped CSV and prepares the stdout preview.
  class CsvOutput
    # Values needed to write one grouped CSV output.
    Request = Struct.new(:options, :headers, :rows, keyword_init: true)

    # File path and preview text produced by a CSV write operation.
    Result = Struct.new(:path, :preview, keyword_init: true)

    def self.write(request)
      new(request).write
    end

    def initialize(request)
      @request = request
    end

    def write
      FileUtils.mkdir_p(File.dirname(path))
      CSV.open(path, "w", write_headers: true, headers: headers) { |csv| write_rows(csv, rows) }

      Result.new(path: path, preview: preview)
    end

    private

    attr_reader :request

    def path
      @path ||= begin
        opts = request.options
        dir = File.expand_path(opts.output_dir || "outputs")
        base = File.basename(opts.input_path, File.extname(opts.input_path))
        File.join(dir, "#{base}_#{opts.matcher}.csv")
      end
    end

    def preview
      CSV.generate do |csv|
        csv << headers
        write_rows(csv, rows.last(100))
      end
    end

    def write_rows(csv, selected_rows)
      selected_rows.each { |row| write_row(csv, row) }
    end

    def write_row(csv, row)
      csv << row_values(row)
    end

    def row_values(row)
      headers.map { |header| row[header] }
    end

    def headers
      request.headers
    end

    def rows
      request.rows
    end
  end
end
