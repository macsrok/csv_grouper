# frozen_string_literal: true

require "csv"

require "csv_grouping/cli_options"
require "csv_grouping/column_resolver"
require "csv_grouping/csv_output"
require "csv_grouping/record_grouper"

module CsvGrouping
  class Application
    def self.call(argv:, stdout:, stderr:)
      new(argv, stdout, stderr).call
    end

    def initialize(argv, stdout, stderr)
      @argv = argv
      @stdout = stdout
      @stderr = stderr
    end

    def call
      options = CliOptions.parse(@argv)
      table = CSV.read(options.input_path, headers: true)
      headers = table.headers
      columns = ColumnResolver.resolve(
        headers: headers,
        email_column: options.email_column,
        phone_column: options.phone_column,
        infer_column_names: options.infer_column_names
      )
      rows = RecordGrouper.group(
        rows: table.map(&:to_h),
        matcher: options.matcher,
        email_columns: columns.email_columns,
        phone_columns: columns.phone_columns
      )
      output = CsvOutput.write(
        input_path: options.input_path,
        matcher: options.matcher,
        headers: ["PersonId"] + headers,
        rows: rows,
        output_dir: options.output_dir
      )

      @stdout.write(output.preview)
      0
    rescue CliOptions::ValidationError,
           ColumnResolver::UnknownColumnError,
           Errno::ENOENT,
           CSV::MalformedCSVError => e
      @stderr.puts("Error: #{e.message}")
      1
    end
  end
end
