# CSV Grouping Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Ruby 4 CSV grouping CLI with a root bash wrapper, deterministic person IDs, matcher-based grouping, output files, stdout preview, tests, and user documentation.

**Architecture:** A root `group_records` bash script performs only wrapper checks and delegates to `ruby -Ilib exe/group_records`. Ruby code is split into focused classes for option parsing, column resolution, grouping, and output writing. Minitest drives behavior with no third-party runtime dependencies beyond Bundler.

**Tech Stack:** Ruby 4, Bundler, stdlib `csv`, stdlib `optparse`, Minitest.

---

## File Structure

- Create `Gemfile`: declares Ruby 4 and uses Minitest for tests.
- Create `Rakefile`: exposes the test task.
- Create `group_records`: root bash wrapper.
- Create `exe/group_records`: Ruby executable entrypoint.
- Create `lib/csv_grouping/application.rb`: coordinates parsing, grouping, writing, and preview output.
- Create `lib/csv_grouping/cli_options.rb`: parses and validates Ruby CLI options.
- Create `lib/csv_grouping/column_resolver.rb`: resolves inferred and explicit email/phone columns.
- Create `lib/csv_grouping/record_grouper.rb`: applies matcher logic and assigns deterministic IDs.
- Create `lib/csv_grouping/csv_output.rb`: writes full CSV and builds last-100 preview.
- Create `lib/csv_grouping/version.rb`: application version constant.
- Create `test/test_helper.rb`: common Minitest setup.
- Create `test/csv_grouping/*_test.rb`: focused unit and integration tests.
- Create `test/wrapper_test.rb`: wrapper behavior tests.
- Create `README.md`: usage, matchers, output, tests, AI process notes.

## Task 1: Project and Test Harness

**Files:**
- Create: `Gemfile`
- Create: `Rakefile`
- Create: `test/test_helper.rb`
- Create: `lib/csv_grouping/version.rb`

- [ ] **Step 1: Write failing harness smoke test**

Create `test/test_helper.rb`:

```ruby
# frozen_string_literal: true

require "minitest/autorun"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
```

Create `test/version_test.rb`:

```ruby
# frozen_string_literal: true

require "test_helper"
require "csv_grouping/version"

class VersionTest < Minitest::Test
  def test_version_is_defined
    refute_nil CsvGrouping::VERSION
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `ruby -Itest test/version_test.rb`

Expected: FAIL or ERROR because `csv_grouping/version` does not exist.

- [ ] **Step 3: Add minimal harness implementation**

Create `Gemfile`:

```ruby
# frozen_string_literal: true

source "https://rubygems.org"

ruby ">= 4.0.0", "< 5.0"

gem "minitest", "~> 5.25", group: :test
```

Create `Rakefile`:

```ruby
# frozen_string_literal: true

require "rake/testtask"

Rake::TestTask.new(:test) do |task|
  task.libs << "test"
  task.pattern = "test/**/*_test.rb"
end

task default: :test
```

Create `lib/csv_grouping/version.rb`:

```ruby
# frozen_string_literal: true

module CsvGrouping
  VERSION = "0.1.0"
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `ruby -Itest test/version_test.rb`

Expected: PASS.

- [ ] **Step 5: Commit**

Run:

```bash
git add Gemfile Rakefile test/test_helper.rb test/version_test.rb lib/csv_grouping/version.rb
git commit -m "Set up Ruby test harness"
```

## Task 2: Column Resolution

**Files:**
- Create: `lib/csv_grouping/column_resolver.rb`
- Test: `test/csv_grouping/column_resolver_test.rb`

- [ ] **Step 1: Write failing tests**

Tests cover default inference, explicit override, explicit plus inferred columns, and unknown explicit columns.

- [ ] **Step 2: Verify red**

Run: `ruby -Itest test/csv_grouping/column_resolver_test.rb`

Expected: ERROR because `CsvGrouping::ColumnResolver` does not exist.

- [ ] **Step 3: Implement minimal resolver**

Implement `CsvGrouping::ColumnResolver.resolve(headers:, email_column:, phone_column:, infer_column_names:)` returning `email_columns` and `phone_columns` arrays. Inference is case-insensitive substring matching for `email` and `phone`.

- [ ] **Step 4: Verify green**

Run: `ruby -Itest test/csv_grouping/column_resolver_test.rb`

Expected: PASS.

- [ ] **Step 5: Commit**

Run:

```bash
git add lib/csv_grouping/column_resolver.rb test/csv_grouping/column_resolver_test.rb
git commit -m "Add column resolution"
```

## Task 3: Record Grouping

**Files:**
- Create: `lib/csv_grouping/record_grouper.rb`
- Test: `test/csv_grouping/record_grouper_test.rb`

- [ ] **Step 1: Write failing tests**

Tests cover case-insensitive email matching, phone digit normalization, `same_email_or_phone` transitive grouping, blank values ignored, and deterministic IDs assigned by first group appearance.

- [ ] **Step 2: Verify red**

Run: `ruby -Itest test/csv_grouping/record_grouper_test.rb`

Expected: ERROR because `CsvGrouping::RecordGrouper` does not exist.

- [ ] **Step 3: Implement minimal grouper**

Implement union-find grouping over row indexes. Normalize email with `strip.downcase`; normalize phone by removing non-digits. Return rows prepended with `PersonId`.

- [ ] **Step 4: Verify green**

Run: `ruby -Itest test/csv_grouping/record_grouper_test.rb`

Expected: PASS.

- [ ] **Step 5: Commit**

Run:

```bash
git add lib/csv_grouping/record_grouper.rb test/csv_grouping/record_grouper_test.rb
git commit -m "Add matcher-based record grouping"
```

## Task 4: CSV Output

**Files:**
- Create: `lib/csv_grouping/csv_output.rb`
- Test: `test/csv_grouping/csv_output_test.rb`

- [ ] **Step 1: Write failing tests**

Tests cover writing the full file to the requested output directory, defaulting to `outputs`, naming files as `<input_basename>_<matcher>.csv`, and previewing the header plus last 100 data rows.

- [ ] **Step 2: Verify red**

Run: `ruby -Itest test/csv_grouping/csv_output_test.rb`

Expected: ERROR because `CsvGrouping::CsvOutput` does not exist.

- [ ] **Step 3: Implement minimal output writer**

Use stdlib `CSV.generate` for preview text and `CSV.open` for file writes. Create output directories with `FileUtils.mkdir_p`.

- [ ] **Step 4: Verify green**

Run: `ruby -Itest test/csv_grouping/csv_output_test.rb`

Expected: PASS.

- [ ] **Step 5: Commit**

Run:

```bash
git add lib/csv_grouping/csv_output.rb test/csv_grouping/csv_output_test.rb
git commit -m "Add CSV output writer"
```

## Task 5: Ruby CLI Application

**Files:**
- Create: `lib/csv_grouping/cli_options.rb`
- Create: `lib/csv_grouping/application.rb`
- Create: `exe/group_records`
- Test: `test/csv_grouping/application_test.rb`
- Test: `test/csv_grouping/cli_options_test.rb`

- [ ] **Step 1: Write failing tests**

Tests cover required Ruby app options, invalid matcher handling, detailed help text, successful end-to-end run against temp CSV input, explicit column behavior, and custom output directory behavior.

- [ ] **Step 2: Verify red**

Run: `ruby -Itest test/csv_grouping/cli_options_test.rb test/csv_grouping/application_test.rb`

Expected: ERROR because CLI and application classes do not exist.

- [ ] **Step 3: Implement minimal CLI and app**

Use `OptionParser` in `CliOptions`. Implement `Application.call(argv:, stdout:, stderr:)`, returning process status codes instead of exiting directly.

- [ ] **Step 4: Verify green**

Run: `ruby -Itest test/csv_grouping/cli_options_test.rb test/csv_grouping/application_test.rb`

Expected: PASS.

- [ ] **Step 5: Commit**

Run:

```bash
git add lib/csv_grouping/cli_options.rb lib/csv_grouping/application.rb exe/group_records test/csv_grouping/application_test.rb test/csv_grouping/cli_options_test.rb
git commit -m "Add Ruby CLI application"
```

## Task 6: Bash Wrapper

**Files:**
- Create: `group_records`
- Test: `test/wrapper_test.rb`

- [ ] **Step 1: Write failing tests**

Tests cover missing `--input`, missing `--matcher`, Ruby major version check, `bundle check` before execution, `bundle install` when gems are missing, and argument passthrough to `exe/group_records`.

- [ ] **Step 2: Verify red**

Run: `ruby -Itest test/wrapper_test.rb`

Expected: ERROR or FAIL because the root wrapper does not exist.

- [ ] **Step 3: Implement minimal wrapper**

Implement bash argument scan, Ruby 4 check with `ruby -e`, Bundler dependency check, and `exec ruby -Ilib exe/group_records "$@"`.

- [ ] **Step 4: Verify green**

Run: `ruby -Itest test/wrapper_test.rb`

Expected: PASS.

- [ ] **Step 5: Commit**

Run:

```bash
git add group_records test/wrapper_test.rb
git commit -m "Add root bash wrapper"
```

## Task 7: Documentation and Full Verification

**Files:**
- Create: `README.md`

- [ ] **Step 1: Write documentation**

Document installation, command examples, arguments, matcher semantics, output behavior, test commands, and AI process notes.

- [ ] **Step 2: Run full test suite**

Run: `bundle exec rake test`

Expected: PASS.

- [ ] **Step 3: Run sample data smoke tests**

Run:

```bash
./group_records --input data/input1.csv --matcher same_email
./group_records --input data/input1.csv --matcher same_phone
./group_records --input data/input2.csv --matcher same_email_or_phone
```

Expected: each command writes a grouped CSV under `outputs/` and prints a CSV preview to stdout.

- [ ] **Step 4: Commit**

Run:

```bash
git add README.md outputs/.gitkeep
git commit -m "Document CSV grouping usage"
```

## Self-Review

- Spec coverage: wrapper, Ruby 4 check, Bundler behavior, three matchers, deterministic IDs, column inference, explicit column override, output directory behavior, stdout preview, help text, tests, and docs are covered.
- Placeholder scan: no `TBD`, `TODO`, or deferred implementation steps remain.
- Type consistency: class and method names are consistent across tasks.
