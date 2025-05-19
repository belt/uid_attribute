# Contributing to uid_attribute

Thanks for your interest in contributing. This guide covers the workflow
and conventions used in this project.

## License

By submitting a contribution you agree that your work is licensed under
the [MIT License](LICENSE). All contributions are subject to the
same license terms.

## Code of Conduct

All participants are expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Getting Started

### Prerequisites

- Ruby 3.4 or newer (CI matrix: 3.4 and 4.0)
- Bundler
- SQLite 3 (used by the in-memory ActiveRecord test harness)

### Setup

```sh
git clone https://github.com/belt/uid_attribute.git
cd uid_attribute
bundle install
git config core.hooksPath .githooks
```

The last command activates the version-controlled pre-push hook
that runs the same checks as CI.

If you use [`mise`](https://mise.jdx.dev), the toolchain is pinned in
`.mise.toml`. Run `mise trust` once on the repo root.

### Running Tests

```sh
bundle exec rspec
```

Coverage thresholds (line ≥ 90, branch ≥ 70) are enforced by SimpleCov.
The full suite runs in under thirty seconds against an in-memory
SQLite database.

### Linting and Formatting

```sh
bundle exec standardrb --no-fix   # check only
bundle exec standardrb            # auto-fix
```

### Code Quality

```sh
bundle exec rake reek      # code-smell detection
bundle exec rake quality   # combined RubyCritic report
bundle exec rake audit     # bundler-audit security check
bundle exec rake ci        # spec + standard + reek + audit
```

## Making Changes

1. Fork the repository and create a branch from `main`.
2. Make your changes in small, focused commits.
3. Add or update tests for any new behavior.
4. Ensure `bundle exec rake ci` passes.
5. Push your branch and open a pull request against `main`.

### Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/) style:

```text
feat(generator): support UUID v8 custom payloads
fix(active_record): preserve preset UID across reload
docs: clarify Railtie auto-registration in README
chore(deps): bump activerecord to 8.1
test(poro): cover initialize with keyword args
```

Scopes mirror the submodule under `lib/uid_attribute/`:
`generator`, `active_record`, `poro`, `core_ext`, `type`, `error`.

### Pull Requests

- Fill out the [PR template](.github/pull_request_template.md).
- Link related issues with `Closes #123`.
- Keep PRs focused on a single concern.
- CI must pass before merge.

## Reporting Bugs

Use the [Bug Report](https://github.com/belt/uid_attribute/issues/new?template=bug_report.yml)
issue template. Include Ruby version, gem version, and a minimal reproduction.

## Requesting Features

Use the [Feature Request](https://github.com/belt/uid_attribute/issues/new?template=feature_request.yml)
issue template. Describe the use case and expected behavior.

## Security Vulnerabilities

Do **not** open a public issue for security vulnerabilities.
See [SECURITY.md](SECURITY.md) for responsible disclosure
instructions.

## Project Layout

```text
.githooks/
  pre-push                  # CI parity gate when pushing to main

lib/uid_attribute/
  generator.rb              # SecureRandom-backed v4/v7 generator
  active_record_integration.rb  # AR mixin (convention-driven)
  poro.rb                   # Plain-Ruby-Object mixin
  type.rb                   # ActiveModel custom :uuid_string type
  railtie.rb                # Rails auto-registration
  core_ext.rb               # Opt-in String refinements
  error.rb                  # Typed exception hierarchy
  version.rb                # VERSION constant

spec/
  spec_helper.rb            # SimpleCov, RSpec config
  support/active_record.rb  # In-memory SQLite schema
  uid_attribute/*_spec.rb   # One spec file per submodule
```

## Architectural Notes

- The top-level `lib/uid_attribute.rb` uses `autoload` so the gem
  can be required without ActiveRecord on the load path.
- `ActiveRecordIntegration` installs a `before_validation(on: :create)`
  callback rather than overriding `#initialize`. Persisted records
  keep their UID through `find` and `reload`.
- `Type` validates and lowercases input in every direction
  (`cast`, `serialize`, `deserialize`) so a value can never round-trip
  through the column without being canonicalized.
- `CoreExt` uses Ruby refinements; no method is added to the `String`
  class globally.
