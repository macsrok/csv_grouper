# frozen_string_literal: true

module CsvGrouping
  # Builds the destination path for grouped CSV output files.
  class OutputPath
    def self.build(request)
      new(request).path
    end

    def initialize(request)
      @request = request
    end

    def path
      File.join(output_dir, filename)
    end

    private

    attr_reader :request

    def output_dir
      File.expand_path(request.output_dir || "outputs")
    end

    def filename
      "#{input_basename}_#{request.matcher}.csv"
    end

    def input_basename
      input_path = request.input_path
      File.basename(input_path, File.extname(input_path))
    end
  end
end
