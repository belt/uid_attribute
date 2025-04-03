# Changelog

Notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-05-28

### Changed

- Module renamed `UIDAttribute` → `UidAttribute` (Ruby naming convention).
- Replaced `uuidtools` runtime dependency with stdlib `SecureRandom`.
- Default UUID version is now **v7** (RFC 9562 §5.7), with v4 available.
- Required Ruby bumped to `>= 3.4.0`.
- Required ActiveSupport / ActiveModel bumped to `>= 7.2`.
- ActiveRecord integration uses `before_validation(on: :create)` instead of
  hijacking `#initialize` — survives `find`, `reload`, and STI correctly.

### Added

- `UidAttribute::Generator` — standalone UUID generation and validation.
- `UidAttribute::Poro` — mixin for plain Ruby objects.
- `UidAttribute::ActiveRecordIntegration` — convention-driven AR mixin.
- `UidAttribute::Type` — ActiveModel custom type, registered as
  `:uuid_string` via Railtie.
- `UidAttribute::CoreExt` — opt-in refinements for `String#uuid?`
  and `String#uuid_version`.
- RSpec 3 test suite, SimpleCov coverage, Standard linting,
  Reek + RubyCritic quality reports, bundler-audit.
- GitHub Actions CI matrix (Ruby 3.4/4.0 × AR 7.2/8.1) with
  SHA-pinned actions and Dependabot.

### Removed

- Global monkey-patches on `String` and `Numeric` (legacy `to_uid`).
  Use `UidAttribute::CoreExt` refinements instead.
- `cover_me` (gem unmaintained) — replaced with SimpleCov.
- Mocha mocking framework — RSpec's built-in mocks are sufficient.
- `uuidtools` runtime dependency.

## [0.3.0] - 2014-01-01

Pre-modernization legacy release.
