# Changelog

Notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Rails generator `uid_attribute:migration` for emitting production-safe
  UUID migrations across PostgreSQL, MySQL, SQLite, Cassandra, Mongoid,
  DynamoDB, and CouchDB.
- Three modes: `add_column` (default), `new_table`, `promote_to_pk`
  (relational adapters only).
- Adapter-aware column types: PostgreSQL native `:uuid`, MySQL CHAR(36)
  or BINARY(16), SQLite TEXT, Cassandra `uuid`/`timeuuid`, MongoDB
  string fields, DynamoDB string attribute + GSI, CouchDB Mango index.
- Concurrent index creation by default on PostgreSQL
  (`disable_ddl_transaction!` + `algorithm: :concurrently`).
- Optional companion backfill migration via `--backfill` for relational
  `add_column` mode (batched, idempotent, references
  `UidAttribute::Generator`).
- Four-step `promote_to_pk` migration set with per-adapter
  `MIGRATION_PLAN.md` documenting deploy sequence, lock implications,
  and `pg_repack` / `pt-online-schema-change` / `gh-ost` integration paths.
- `--extra-columns name:type ...` for `new_table` mode.
- `--as-pk` for using the UUID column as the primary key.
- DynamoDB output: `db/dynamodb_migrate/` Ruby scripts using
  `aws-sdk-dynamodb` for `create_table` / GSI updates.
- CouchDB output: `db/couchdb_migrate/` Ruby scripts using stdlib
  `Net::HTTP` to create databases, backfill, and declare Mango indexes.
- End-to-end integration specs: generated SQLite migrations are loaded
  and executed against an in-memory database, with assertions on actual
  column types, indexes, NOT NULL constraints, and backfilled UUID values.

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
