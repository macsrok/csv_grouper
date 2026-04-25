# CSV Grouping Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Ruby 4 CSV grouping CLI with a root bash wrapper, deterministic person IDs, matcher-based grouping, output files, stdout preview, tests, and user documentation.

**Architecture:** A root `group_records` bash script performs only wrapper checks and delegates to `ruby -Ilib exe/group_records`. Ruby code is split into focused classes for option parsing, column resolution, grouping, and output writing. RSpec drives behavior through focused specs.

**Tech Stack:** Ruby 4, Bundler, stdlib `csv`, stdlib `optparse`, RSpec.

---

## File Structure

- Create `Gemfile`: declares Ruby 4 and uses RSpec for tests.
- Create `Rakefile`: exposes the test task.
- Create `.rspec`: configures RSpec output.
- Create `group_records`: root bash wrapper.
- Create `exe/group_records`: Ruby executable entrypoint.
- Create `lib/csv_grouping/application.rb`: coordinates parsing, grouping, writing, and preview output.
- Create `lib/csv_grouping/cli_options.rb`: parses and validates Ruby CLI options.
- Create `lib/csv_grouping/column_resolver.rb`: resolves inferred and explicit email/phone columns.
- Create `lib/csv_grouping/record.rb`: wraps a CSV row, normalizes values at creation time, and exposes matcher keys.
- Create `lib/csv_grouping/record_grouper.rb`: groups records by matcher keys and assigns deterministic IDs.
- Create `lib/csv_grouping/csv_output.rb`: writes full CSV and builds last-100 preview.
- Create `lib/csv_grouping/version.rb`: application version constant.
- Create `spec/spec_helper.rb`: common RSpec setup.
- Create `spec/csv_grouping/*_spec.rb`: focused unit and integration specs.
- Create `spec/wrapper_spec.rb`: wrapper behavior specs.
- Create `README.md`: usage, matchers, output, tests, AI process notes.

## Task 1: Project and Test Harness

**Files:**
- Create: `Gemfile`
- Create: `Rakefile`
- Create: `.rspec`
- Create: `spec/spec_helper.rb`
- Create: `lib/csv_grouping/version.rb`

- [ ] **Step 1: Write failing harness smoke test**

Create `spec/spec_helper.rb`:

```ruby
# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
```

Create `spec/version_spec.rb`:

```ruby
# frozen_string_literal: true

require "spec_helper"
require "csv_grouping/version"

RSpec.describe CsvGrouping::VERSION do
  it "is defined" do
    expect(CsvGrouping::VERSION).not_to be_nil
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `rspec spec/version_spec.rb`

Expected: FAIL or ERROR because `csv_grouping/version` does not exist.

- [ ] **Step 3: Add minimal harness implementation**

Create `Gemfile`:

```ruby
# frozen_string_literal: true

source "https://rubygems.org"

ruby ">= 4.0.0", "< 5.0"

gem "rspec", "~> 3.13", group: :test
```

Create `Rakefile`:

```ruby
# frozen_string_literal: true

require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec
```

Create `lib/csv_grouping/version.rb`:

```ruby
# frozen_string_literal: true

module CsvGrouping
  VERSION = "0.1.0"
end
```

- [ ] **Step 4: Run test to verify it passes**

Run: `rspec spec/version_spec.rb`

Expected: PASS.

- [ ] **Step 5: Commit**

Run:

```bash
git add .rspec Gemfile Rakefile spec/spec_helper.rb spec/version_spec.rb lib/csv_grouping/version.rb docs/superpowers/specs/2026-04-25-csv-grouping-design.md docs/superpowers/plans/2026-04-25-csv-grouping.md
git commit -m "Set up Ruby test harness"
```

## Task 2: Column Resolution

**Files:**
- Create: `lib/csv_grouping/column_resolver.rb`
- Test: `spec/csv_grouping/column_resolver_spec.rb`

- [ ] **Step 1: Write failing tests**

Tests cover default inference, explicit override, explicit plus inferred columns, and unknown explicit columns.

- [ ] **Step 2: Verify red**

Run: `rspec spec/csv_grouping/column_resolver_spec.rb`

Expected: ERROR because `CsvGrouping::ColumnResolver` does not exist.

- [ ] **Step 3: Implement minimal resolver**

Implement `CsvGrouping::ColumnResolver.resolve(headers:, email_column:, phone_column:, infer_column_names:)` returning `email_columns` and `phone_columns` arrays. Inference is case-insensitive substring matching for `email` and `phone`.

- [ ] **Step 4: Verify green**

Run: `rspec spec/csv_grouping/column_resolver_spec.rb`

Expected: PASS.

- [ ] **Step 5: Commit**

Run:

```bash
git add lib/csv_grouping/column_resolver.rb spec/csv_grouping/column_resolver_spec.rb
git commit -m "Add column resolution"
```

## Task 3: Record Grouping

**Files:**
- Create: `lib/csv_grouping/record.rb`
- Create: `lib/csv_grouping/record_grouper.rb`
- Test: `spec/csv_grouping/record_spec.rb`
- Test: `spec/csv_grouping/record_grouper_spec.rb`

- [ ] **Step 1: Write failing tests**

Tests cover record-level case-insensitive email normalization, phone digit normalization, matcher key extraction, blank values ignored, `same_email_or_phone` transitive grouping, and deterministic IDs assigned by first group appearance.

- [ ] **Step 2: Verify red**

Run: `rspec spec/csv_grouping/record_spec.rb spec/csv_grouping/record_grouper_spec.rb`

Expected: ERROR because `CsvGrouping::Record` and `CsvGrouping::RecordGrouper` do not exist.

- [ ] **Step 3: Implement minimal grouper**

Implement `CsvGrouping::Record` so each instance wraps a row, normalizes email with `strip.downcase`, normalizes phone by removing non-digits, and exposes `keys_for(matcher)`. Implement union-find grouping over record indexes in `CsvGrouping::RecordGrouper`. Return rows prepended with `PersonId`.

- [ ] **Step 4: Verify green**

Run: `rspec spec/csv_grouping/record_spec.rb spec/csv_grouping/record_grouper_spec.rb`

Expected: PASS.

- [ ] **Step 5: Commit**

Run:

```bash
git add lib/csv_grouping/record.rb lib/csv_grouping/record_grouper.rb spec/csv_grouping/record_spec.rb spec/csv_grouping/record_grouper_spec.rb docs/superpowers/specs/2026-04-25-csv-grouping-design.md docs/superpowers/plans/2026-04-25-csv-grouping.md
git commit -m "Add matcher-based record grouping"
```

## Task 4: CSV Output

**Files:**
- Create: `lib/csv_grouping/csv_output.rb`
- Test: `spec/csv_grouping/csv_output_spec.rb`

- [ ] **Step 1: Write failing tests**

Tests cover writing the full file to the requested output directory, defaulting to `outputs`, naming files as `<input_basename>_<matcher>.csv`, and previewing the header plus last 100 data rows.

- [ ] **Step 2: Verify red**

Run: `rspec spec/csv_grouping/csv_output_spec.rb`

Expected: ERROR because `CsvGrouping::CsvOutput` does not exist.

- [ ] **Step 3: Implement minimal output writer**

Use stdlib `CSV.generate` for preview text and `CSV.open` for file writes. Create output directories with `FileUtils.mkdir_p`.

- [ ] **Step 4: Verify green**

Run: `rspec spec/csv_grouping/csv_output_spec.rb`

Expected: PASS.

- [ ] **Step 5: Commit**

Run:

```bash
git add lib/csv_grouping/csv_output.rb spec/csv_grouping/csv_output_spec.rb
git commit -m "Add CSV output writer"
```

## Task 5: Ruby CLI Application

**Files:**
- Create: `lib/csv_grouping/cli_options.rb`
- Create: `lib/csv_grouping/application.rb`
- Create: `exe/group_records`
- Test: `spec/csv_grouping/application_spec.rb`
- Test: `spec/csv_grouping/cli_options_spec.rb`

- [ ] **Step 1: Write failing tests**

Tests cover required Ruby app options, invalid matcher handling, detailed help text, successful end-to-end run against temp CSV input, explicit column behavior, and custom output directory behavior.

- [ ] **Step 2: Verify red**

Run: `rspec spec/csv_grouping/cli_options_spec.rb spec/csv_grouping/application_spec.rb`

Expected: ERROR because CLI and application classes do not exist.

- [ ] **Step 3: Implement minimal CLI and app**

Use `OptionParser` in `CliOptions`. Implement `Application.call(argv:, stdout:, stderr:)`, returning process status codes instead of exiting directly.

- [ ] **Step 4: Verify green**

Run: `rspec spec/csv_grouping/cli_options_spec.rb spec/csv_grouping/application_spec.rb`

Expected: PASS.

- [ ] **Step 5: Commit**

Run:

```bash
git add lib/csv_grouping/cli_options.rb lib/csv_grouping/application.rb exe/group_records spec/csv_grouping/application_spec.rb spec/csv_grouping/cli_options_spec.rb
git commit -m "Add Ruby CLI application"
```

## Task 6: Bash Wrapper

**Files:**
- Create: `group_records`
- Test: `spec/wrapper_spec.rb`

- [ ] **Step 1: Write failing tests**

Tests cover missing `--input`, missing `--matcher`, Ruby major version check, `bundle check` before execution, `bundle install` when gems are missing, and argument passthrough to `exe/group_records`.

- [ ] **Step 2: Verify red**

Run: `rspec spec/wrapper_spec.rb`

Expected: ERROR or FAIL because the root wrapper does not exist.

- [ ] **Step 3: Implement minimal wrapper**

Implement bash argument scan, Ruby 4 check with `ruby -e`, Bundler dependency check, and `exec ruby -Ilib exe/group_records "$@"`.

- [ ] **Step 4: Verify green**

Run: `rspec spec/wrapper_spec.rb`

Expected: PASS.

- [ ] **Step 5: Commit**

Run:

```bash
git add group_records spec/wrapper_spec.rb
git commit -m "Add root bash wrapper"
```

## Task 7: Documentation and Full Verification

**Files:**
- Create: `README.md`

- [ ] **Step 1: Write documentation**

Document installation, command examples, arguments, matcher semantics, output behavior, test commands, and AI process notes.

- [ ] **Step 2: Run full test suite**

Run: `bundle exec rake spec`

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
