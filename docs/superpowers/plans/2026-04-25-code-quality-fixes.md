# Code Quality Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Address all 12 Ruby best-practice issues flagged in the hiring-manager review, without changing any observable behavior.

**Architecture:** Pure refactoring — no behavior changes. Each task touches one or two files, leaves all 36 existing tests green, and adds new tests where coverage was missing. Tests are run after every task.

**Tech Stack:** Ruby 4, RSpec 3, SimpleCov

---

## File Map

| File | Change |
|---|---|
| `lib/csv_grouping/record.rb` | Remove lambda constants; privatize `all_keys`/`empty_keys`; use `send` |
| `lib/csv_grouping/record_grouper.rb` | Remove `EMPTY_KEY_INDEX` constant; remove `MATCHERS` constant |
| `lib/csv_grouping/group_id_assigner.rb` | Replace `tap`-based side-effect with explicit local variable |
| `lib/csv_grouping/csv_output.rb` | Inline `OutputPath` logic; remove `Request` proxy methods |
| `lib/csv_grouping/output_path.rb` | **Delete** — logic moved into `CsvOutput` |
| `lib/csv_grouping/cli_options.rb` | Add `MATCHERS`; resolve `infer_column_names` nil→true; remove RecordGrouper require |
| `lib/csv_grouping/column_resolver.rb` | Switch `initialize` to keyword arguments |
| `lib/csv_grouping/union_find.rb` | Replace recursive `find` with iterative path-compression |
| `spec/csv_grouping/union_find_spec.rb` | **New** — unit tests for UnionFind |
| `spec/csv_grouping/group_id_assigner_spec.rb` | **New** — unit tests for GroupIdAssigner |
| `spec/csv_grouping/cli_options_spec.rb` | Update `infer_column_names` default expectation (`nil` → `true`) |
| `spec/spec_helper.rb` | Add SimpleCov |
| `Gemfile` | Add `simplecov` |

---

### Task 1: Fix `Record` — lambda constants → private methods, privatize internal helpers

**Files:**
- Modify: `lib/csv_grouping/record.rb`

- [ ] **Step 1: Confirm existing Record tests pass**

```bash
bundle exec rspec spec/csv_grouping/record_spec.rb -f doc
```
Expected: 7 examples, 0 failures

- [ ] **Step 2: Replace lambda constants and privatize helpers**

Replace the entire file content with:

```ruby
# frozen_string_literal: true

module CsvGrouping
  # Wraps one CSV row and exposes pre-normalized matcher keys.
  class Record
    MATCHER_KEY_READERS = {
      "same_email" => :email_keys,
      "same_phone" => :phone_keys,
      "same_email_or_phone" => :all_keys
    }.freeze

    attr_reader :row, :email_keys, :phone_keys

    def initialize(row, email_columns:, phone_columns:)
      @row = row
      @email_keys = email_columns.filter_map { |col| email_key(row[col]) }
      @phone_keys = phone_columns.filter_map { |col| phone_key(row[col]) }
    end

    def keys_for(matcher)
      reader = MATCHER_KEY_READERS.fetch(matcher, :empty_keys)
      send(reader)
    end

    private

    def all_keys
      email_keys + phone_keys
    end

    def empty_keys
      []
    end

    def email_key(value)
      normalized = value.to_s.strip.downcase
      "email:#{normalized}" unless normalized.empty?
    end

    def phone_key(value)
      normalized = value.to_s.gsub(/\D/, "")
      "phone:#{normalized}" unless normalized.empty?
    end
  end
end
```

- [ ] **Step 3: Confirm tests still pass**

```bash
bundle exec rspec spec/csv_grouping/record_spec.rb -f doc
```
Expected: 7 examples, 0 failures

- [ ] **Step 4: Commit**

```bash
git add lib/csv_grouping/record.rb
git commit -m "refactor(record): replace lambda constants with private methods, privatize all_keys/empty_keys"
```

---

### Task 2: Fix `RecordGrouper` — remove `EMPTY_KEY_INDEX` lambda constant

**Files:**
- Modify: `lib/csv_grouping/record_grouper.rb`

- [ ] **Step 1: Confirm existing tests pass**

```bash
bundle exec rspec spec/csv_grouping/record_grouper_spec.rb -f doc
```
Expected: 4 examples, 0 failures

- [ ] **Step 2: Inline the hash construction**

In `record_grouper.rb`, remove line 11 (`EMPTY_KEY_INDEX = ...`) and update `indexes_by_key`:

```ruby
# frozen_string_literal: true

require "csv_grouping/group_id_assigner"
require "csv_grouping/record"
require "csv_grouping/union_find"

module CsvGrouping
  # Builds transitive person groups from each record's matcher keys.
  class RecordGrouper
    # Values needed to build person groups from CSV rows.
    Request = Struct.new(:rows, :matcher, :email_columns, :phone_columns, keyword_init: true)

    def self.group(request)
      new(request).group
    end

    def initialize(request)
      rows = request.rows
      @records = rows.map do |row|
        Record.new(row, email_columns: request.email_columns, phone_columns: request.phone_columns)
      end
      @matcher = request.matcher
      @union_find = UnionFind.new(rows.length)
    end

    def group
      union_matching_records
      assign_group_ids
    end

    private

    def union_matching_records
      indexes_by_key.each_value { |indexes| union_indexes(indexes) }
    end

    def union_indexes(indexes)
      first = indexes.first
      indexes.drop(1).each { |index| @union_find.union(first, index) }
    end

    def assign_group_ids
      assigner = GroupIdAssigner.new

      @records.each_with_index.map do |record, index|
        root = @union_find.find(index)
        { "PersonId" => assigner.id_for(root) }.merge(record.row)
      end
    end

    def indexes_by_key
      keys = Hash.new { |hash, key| hash[key] = [] }

      @records.each_with_index do |record, index|
        store_record_keys(keys, record, index)
      end

      keys
    end

    def store_record_keys(keys, record, index)
      record.keys_for(@matcher).each { |key| keys[key] << index }
    end
  end
end
```

- [ ] **Step 3: Confirm tests pass**

```bash
bundle exec rspec spec/csv_grouping/record_grouper_spec.rb -f doc
```
Expected: 4 examples, 0 failures

- [ ] **Step 4: Commit**

```bash
git add lib/csv_grouping/record_grouper.rb
git commit -m "refactor(record_grouper): inline empty key index hash, remove EMPTY_KEY_INDEX lambda constant"
```

---

### Task 3: Fix `GroupIdAssigner` — replace `tap` side-effect with explicit local

**Files:**
- Modify: `lib/csv_grouping/group_id_assigner.rb`

- [ ] **Step 1: Confirm tests still run (no direct spec yet — full suite)**

```bash
bundle exec rspec spec/ -f doc 2>&1 | tail -5
```
Expected: 0 failures

- [ ] **Step 2: Replace `tap` with explicit local**

```ruby
# frozen_string_literal: true

module CsvGrouping
  # Assigns stable sequential PersonId values to connected record roots.
  class GroupIdAssigner
    def initialize
      @group_ids = {}
      @next_id = 1
    end

    def id_for(root)
      @group_ids[root] ||= next_group_id
    end

    private

    def next_group_id
      id = @next_id
      @next_id += 1
      id.to_s
    end
  end
end
```

- [ ] **Step 3: Confirm tests pass**

```bash
bundle exec rspec spec/ 2>&1 | tail -3
```
Expected: 0 failures

- [ ] **Step 4: Commit**

```bash
git add lib/csv_grouping/group_id_assigner.rb
git commit -m "refactor(group_id_assigner): replace tap-based mutation with explicit local variable"
```

---

### Task 4: Add tests for `UnionFind` and `GroupIdAssigner`

**Files:**
- Create: `spec/csv_grouping/union_find_spec.rb`
- Create: `spec/csv_grouping/group_id_assigner_spec.rb`

- [ ] **Step 1: Write UnionFind spec**

```ruby
# frozen_string_literal: true

require "spec_helper"
require "csv_grouping/union_find"

RSpec.describe CsvGrouping::UnionFind do
  subject(:uf) { described_class.new(5) }

  describe "#find" do
    it "returns each index as its own root initially" do
      expect((0..4).map { |i| uf.find(i) }).to eq([0, 1, 2, 3, 4])
    end

    it "applies path compression on repeated find" do
      uf.union(0, 1)
      uf.union(1, 2)
      uf.find(2)
      expect(uf.find(2)).to eq(uf.find(0))
    end
  end

  describe "#union" do
    it "connects two separate indexes" do
      uf.union(0, 1)
      expect(uf.find(0)).to eq(uf.find(1))
    end

    it "is idempotent when indexes are already connected" do
      uf.union(0, 1)
      uf.union(0, 1)
      expect(uf.find(0)).to eq(uf.find(1))
    end

    it "does not connect unrelated indexes" do
      uf.union(0, 1)
      expect(uf.find(2)).not_to eq(uf.find(0))
    end

    it "supports transitive connections" do
      uf.union(0, 1)
      uf.union(1, 2)
      expect(uf.find(0)).to eq(uf.find(2))
    end
  end
end
```

- [ ] **Step 2: Run — expect pass (behavior unchanged)**

```bash
bundle exec rspec spec/csv_grouping/union_find_spec.rb -f doc
```
Expected: 6 examples, 0 failures

- [ ] **Step 3: Write GroupIdAssigner spec**

```ruby
# frozen_string_literal: true

require "spec_helper"
require "csv_grouping/group_id_assigner"

RSpec.describe CsvGrouping::GroupIdAssigner do
  subject(:assigner) { described_class.new }

  describe "#id_for" do
    it "assigns 1 to the first root seen" do
      expect(assigner.id_for(0)).to eq("1")
    end

    it "assigns incrementing ids to new roots" do
      expect(assigner.id_for(0)).to eq("1")
      expect(assigner.id_for(3)).to eq("2")
      expect(assigner.id_for(7)).to eq("3")
    end

    it "returns the same id for the same root on repeated calls" do
      assigner.id_for(0)
      assigner.id_for(1)
      expect(assigner.id_for(0)).to eq("1")
    end

    it "returns string ids" do
      expect(assigner.id_for(0)).to be_a(String)
    end
  end
end
```

- [ ] **Step 4: Run — expect pass**

```bash
bundle exec rspec spec/csv_grouping/group_id_assigner_spec.rb -f doc
```
Expected: 4 examples, 0 failures

- [ ] **Step 5: Commit**

```bash
git add spec/csv_grouping/union_find_spec.rb spec/csv_grouping/group_id_assigner_spec.rb
git commit -m "test: add unit specs for UnionFind and GroupIdAssigner"
```

---

### Task 5: Make `UnionFind#find` iterative

**Files:**
- Modify: `lib/csv_grouping/union_find.rb`

- [ ] **Step 1: Confirm UnionFind tests pass (baseline)**

```bash
bundle exec rspec spec/csv_grouping/union_find_spec.rb -f doc
```
Expected: 6 examples, 0 failures

- [ ] **Step 2: Replace recursive find with iterative path compression**

```ruby
# frozen_string_literal: true

module CsvGrouping
  # Tracks connected record indexes for transitive person matching.
  class UnionFind
    def initialize(size)
      @parents = Array.new(size) { |index| index }
    end

    def find(index)
      root = index
      root = @parents[root] until @parents[root] == root

      current = index
      while current != root
        next_node = @parents[current]
        @parents[current] = root
        current = next_node
      end

      root
    end

    def union(left, right)
      left_root = find(left)
      right_root = find(right)
      return if left_root == right_root

      @parents[right_root] = left_root
    end
  end
end
```

- [ ] **Step 3: Confirm tests pass**

```bash
bundle exec rspec spec/csv_grouping/union_find_spec.rb spec/csv_grouping/record_grouper_spec.rb -f doc
```
Expected: 10 examples, 0 failures

- [ ] **Step 4: Commit**

```bash
git add lib/csv_grouping/union_find.rb
git commit -m "refactor(union_find): replace recursive find with iterative path compression"
```

---

### Task 6: Fix `CliOptions` — own `MATCHERS`, remove cross-layer coupling, resolve `infer_column_names` default

**Files:**
- Modify: `lib/csv_grouping/cli_options.rb`
- Modify: `lib/csv_grouping/record_grouper.rb` (remove `MATCHERS` constant)
- Modify: `spec/csv_grouping/cli_options_spec.rb` (update nil→true expectation)

- [ ] **Step 1: Confirm cli_options tests pass (baseline)**

```bash
bundle exec rspec spec/csv_grouping/cli_options_spec.rb -f doc
```
Expected: 5 examples, 0 failures

- [ ] **Step 2: Update `cli_options_spec.rb` to expect `true` instead of `nil`**

In `spec/csv_grouping/cli_options_spec.rb`, change the `infer_column_names` expectation in the "parses defaults" example:

```ruby
it "parses defaults" do
  expect(options.input_path).to eq("data/input.csv")
  expect(options.matcher).to eq("same_email")
  expect(options.output_dir).to be_nil
  expect(options.email_column).to be_nil
  expect(options.phone_column).to be_nil
  expect(options.infer_column_names).to be(true)
end
```

- [ ] **Step 3: Run — expect the one changed example to fail**

```bash
bundle exec rspec spec/csv_grouping/cli_options_spec.rb -f doc
```
Expected: 1 failure on `infer_column_names`

- [ ] **Step 4: Update `cli_options.rb`**

```ruby
# frozen_string_literal: true

require "optparse"

require "csv_grouping/errors"

module CsvGrouping
  # Parses and validates command-line options after the shell wrapper delegates.
  class CliOptions
    MATCHERS = %w[same_email same_phone same_email_or_phone].freeze

    BOOLEAN_VALUES = {
      "true" => true,
      "false" => false
    }.freeze

    # Immutable option values consumed by the application runner.
    Options = Struct.new(
      :input_path,
      :matcher,
      :output_dir,
      :email_column,
      :phone_column,
      :infer_column_names,
      keyword_init: true
    )

    def self.parse(argv)
      new(argv).parse
    end

    def initialize(argv)
      @argv = argv
      @values = {}
    end

    def parse
      parser.parse!(@argv)
      validate
      Options.new(**@values)
    rescue OptionParser::ParseError => error
      raise ValidationError, error.message
    end

    private

    def parser
      OptionParser.new do |opts|
        add_value_options(opts)
        add_boolean_options(opts)
      end
    end

    def add_value_options(opts)
      add_value_option(opts, :input_path, "--input PATH")
      add_value_option(opts, :matcher, "--matcher MATCHER")
      add_value_option(opts, :output_dir, "--output-dir DIR", "--output_dir DIR")
      add_value_option(opts, :email_column, "--email-column COLUMN", "--email_column COLUMN")
      add_value_option(opts, :phone_column, "--phone-column COLUMN", "--phone_column COLUMN")
    end

    def add_boolean_options(opts)
      add_boolean_option(opts, :infer_column_names, "--infer-column-names VALUE", "--infer_column_names VALUE")
    end

    def add_value_option(opts, key, *names)
      opts.on(*names) { |value| @values[key] = value }
    end

    def add_boolean_option(opts, key, *names)
      opts.on(*names) { |value| @values[key] = parse_boolean(value) }
    end

    def validate
      matcher = @values[:matcher]

      raise ValidationError, "input is required" if @values[:input_path].to_s.empty?
      raise ValidationError, "matcher is required" if matcher.to_s.empty?

      unless MATCHERS.include?(matcher)
        raise ValidationError, "matcher must be one of #{MATCHERS.join(', ')}"
      end

      @values[:infer_column_names] = true if @values[:infer_column_names].nil?
    end

    def parse_boolean(value)
      BOOLEAN_VALUES.fetch(value.to_s.downcase) do
        raise ValidationError, "infer-column-names must be true or false"
      end
    end
  end
end
```

- [ ] **Step 5: Remove `MATCHERS` from `record_grouper.rb`**

In `lib/csv_grouping/record_grouper.rb`, delete the line:

```ruby
MATCHERS = %w[same_email same_phone same_email_or_phone].freeze
```

The `RecordGrouper` class does not need this constant for its own logic.

- [ ] **Step 6: Run all tests**

```bash
bundle exec rspec spec/ 2>&1 | tail -5
```
Expected: 0 failures

- [ ] **Step 7: Commit**

```bash
git add lib/csv_grouping/cli_options.rb lib/csv_grouping/record_grouper.rb spec/csv_grouping/cli_options_spec.rb
git commit -m "refactor(cli_options): own MATCHERS constant, remove RecordGrouper coupling, default infer_column_names to true"
```

---

### Task 7: Fix `ColumnResolver` — keyword args in `initialize`

**Files:**
- Modify: `lib/csv_grouping/column_resolver.rb`

- [ ] **Step 1: Confirm column_resolver tests pass**

```bash
bundle exec rspec spec/csv_grouping/column_resolver_spec.rb -f doc
```
Expected: 5 examples, 0 failures

- [ ] **Step 2: Update `initialize` to use keyword arguments**

```ruby
# frozen_string_literal: true

module CsvGrouping
  # Resolves the CSV columns used as email and phone match sources.
  class ColumnResolver
    # Column lists selected for email and phone matching.
    Result = Struct.new(:email_columns, :phone_columns, keyword_init: true)

    def self.resolve(headers:, email_column:, phone_column:, infer_column_names:)
      new(headers:, email_column:, phone_column:, infer_column_names:).resolve
    end

    def initialize(headers:, email_column:, phone_column:, infer_column_names:)
      @headers = headers
      @email_column = email_column
      @phone_column = phone_column
      @infer_column_names = infer_column_names
    end

    def resolve
      Result.new(
        email_columns: resolve_type("email", @email_column),
        phone_columns: resolve_type("phone", @phone_column)
      )
    end

    private

    def resolve_type(type, explicit_column)
      inferred = @headers.select { |header| header.downcase.include?(type) }
      return inferred if !explicit_column && @infer_column_names != false

      return [] unless explicit_column

      validate_explicit_column(type, explicit_column)
      selected = [explicit_column]
      selected.concat(inferred) if @infer_column_names == true
      selected.uniq
    end

    def validate_explicit_column(type, column)
      return if @headers.include?(column)

      raise_unknown_column(type, column)
    end

    def raise_unknown_column(type, column)
      raise UnknownColumnError,
            "#{type} column \"#{column}\" was not found. Available columns: #{@headers.join(', ')}"
    end
  end
end
```

- [ ] **Step 3: Confirm tests pass**

```bash
bundle exec rspec spec/csv_grouping/column_resolver_spec.rb -f doc
```
Expected: 5 examples, 0 failures

- [ ] **Step 4: Commit**

```bash
git add lib/csv_grouping/column_resolver.rb
git commit -m "refactor(column_resolver): use keyword arguments in initialize for consistency with class factory"
```

---

### Task 8: Simplify `CsvOutput` — inline `OutputPath`, remove `Request` proxy methods

**Files:**
- Modify: `lib/csv_grouping/csv_output.rb`
- Delete: `lib/csv_grouping/output_path.rb`

- [ ] **Step 1: Confirm CsvOutput tests pass**

```bash
bundle exec rspec spec/csv_grouping/csv_output_spec.rb -f doc
```
Expected: 3 examples, 0 failures

- [ ] **Step 2: Rewrite `csv_output.rb` with inlined path logic and simplified Request**

```ruby
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
```

- [ ] **Step 3: Remove `output_path.rb`**

```bash
git rm lib/csv_grouping/output_path.rb
```

- [ ] **Step 4: Confirm tests pass**

```bash
bundle exec rspec spec/csv_grouping/csv_output_spec.rb spec/csv_grouping/application_spec.rb -f doc
```
Expected: 0 failures

- [ ] **Step 5: Run full suite**

```bash
bundle exec rspec spec/ 2>&1 | tail -5
```
Expected: 0 failures

- [ ] **Step 6: Commit**

```bash
git add lib/csv_grouping/csv_output.rb
git commit -m "refactor(csv_output): inline OutputPath logic, remove Request proxy methods, delete output_path.rb"
```

---

### Task 9: Add SimpleCov

**Files:**
- Modify: `Gemfile`
- Modify: `spec/spec_helper.rb`

- [ ] **Step 1: Add simplecov to Gemfile**

In `Gemfile`, add after the existing test gem line:

```ruby
gem "simplecov", require: false, group: :test
```

- [ ] **Step 2: Run bundle install**

```bash
bundle install
```
Expected: Fetches and installs simplecov

- [ ] **Step 3: Update spec_helper**

```ruby
# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  minimum_coverage 90
end

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
```

- [ ] **Step 4: Run full suite**

```bash
bundle exec rspec spec/ 2>&1 | tail -10
```
Expected: 0 failures, coverage reported at ≥ 90%

- [ ] **Step 5: Commit**

```bash
git add Gemfile Gemfile.lock spec/spec_helper.rb
git commit -m "chore: add SimpleCov with 90% minimum coverage gate"
```

---

## Self-Review

**Spec coverage:** All 12 flagged issues are addressed:
1. ✅ Lambda constants → private methods (`Record`, Task 1)
2. ✅ `EMPTY_KEY_INDEX` → inlined hash (Task 2)
3. ✅ `all_keys`/`empty_keys` privatized, `send` used (Task 1)
4. ✅ `tap` side-effect → local variable (Task 3)
5. ✅ `CsvOutput::Request` proxy methods removed (Task 8)
6. ✅ `OutputPath` class deleted, logic inlined (Task 8)
7. ✅ `MATCHERS` moved to `CliOptions`, RecordGrouper coupling removed (Task 6)
8. ✅ `infer_column_names` nil resolved to `true` (Task 6)
9. ✅ `ColumnResolver#initialize` keyword args (Task 7)
10. ✅ `UnionFind` and `GroupIdAssigner` unit tests added (Task 4)
11. ✅ `UnionFind#find` iterative (Task 5)
12. ✅ SimpleCov added (Task 9)

**Placeholder scan:** No TBDs or stubs found.

**Type consistency:** `CliOptions::MATCHERS` is the only definition; `RecordGrouper` no longer defines it. `ColumnResolver.resolve` and `.initialize` both use keyword args. `CsvOutput::Request` no longer has proxy methods — callers use `request.options.matcher` etc.
