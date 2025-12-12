# UidAttribute

Auto-assign UUIDs to PORO and ActiveRecord attributes. Defaults to
UUID v7 (RFC 9562 §5.7) — time-ordered, monotonic, B-tree friendly —
with v4 (RFC 9562 §5.4) available when entropy beats time-ordering.

This gem is to UUIDs what
[`ip_attribute`](https://github.com/belt/ip_attribute) is to IP
addresses: a thin, convention-driven layer that auto-detects an
attribute and keeps it populated.

## Installation

```ruby
gem "uid_attribute"
```

## ActiveRecord

Convention: any column named `uid` or `uuid` is auto-detected.

```ruby
class Order < ActiveRecord::Base
  include UidAttribute::ActiveRecordIntegration
end

Order.create!.uid  # => "018f4d9c-7a8b-7000-9b2a-1c3d4e5f6a7b" (v7)
```

Override the column or version explicitly:

```ruby
class Order < ActiveRecord::Base
  include UidAttribute::ActiveRecordIntegration
  uid_attribute :public_id, version: 4
end
```

The mixin installs a `before_validation(on: :create)` callback that
populates the attribute when blank. Presence and uniqueness validators
are added by default — disable with `validate: false`.

## PORO

```ruby
class Job
  include UidAttribute::Poro
  attr_accessor :uid
end

Job.new.uid  # => "018f4d9c-..."
```

Custom attribute and version:

```ruby
class Job
  include UidAttribute::Poro
  attr_accessor :public_id
  uid_attribute :public_id, version: 4
end
```

## Standalone Generator

No mixin required:

```ruby
UidAttribute::Generator.generate              # => v7 (default)
UidAttribute::Generator.generate(version: 4)  # => v4
UidAttribute::Generator.valid?(str)           # => true / false
UidAttribute::Generator.version_of(str)       # => 1..7 or nil
```

## ActiveModel Type

For non-AR models or explicit AR columns:

```ruby
class Request
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :token, UidAttribute::Type.new
end
```

With Rails, `:uuid_string` is auto-registered via Railtie:

```ruby
attribute :public_id, :uuid_string
```

## Opt-in Refinements

```ruby
require "uid_attribute/core_ext"
using UidAttribute::CoreExt

"018f4d9c-7a8b-7000-9b2a-1c3d4e5f6a7b".uuid?         # => true
"018f4d9c-7a8b-7000-9b2a-1c3d4e5f6a7b".uuid_version  # => 7
```

Lexically scoped — no global monkey-patching.

## Rails generator: migrations

Generate production-safe UUID migrations from the Rails CLI. The
generator detects your adapter and emits the appropriate column type,
index strategy, and lock-management hints.

### Modes

| Mode | Use when |
| ---- | -------- |
| `add_column` (default) | Adding a UUID to an existing table |
| `new_table` | Creating a fresh table with a UUID column |
| `promote_to_pk` | Migrating an integer primary key to UUID |

### Adapters

| Adapter | Column type | Notes |
| ------- | ----------- | ----- |
| `postgresql` | native `:uuid` | concurrent unique index by default |
| `mysql` | `CHAR(36)` (default) or `BINARY(16)` | online DDL where supported |
| `sqlite` | TEXT | limited online DDL story documented |
| `cassandra` | `uuid` or `timeuuid` | emits `.cql` files in `db/cql_migrate/` |
| `mongoid` | string field | requires `mongoid_rails_migrations` |
| `dynamodb` | string + GSI | `db/dynamodb_migrate/`, uses `aws-sdk-dynamodb` |
| `couchdb` | Mango index | `db/couchdb_migrate/`, stdlib `Net::HTTP` |

### Examples

```bash
# Default: add a :uuid column to orders, with concurrent unique index
bin/rails generate uid_attribute:migration Order

# Companion backfill migration for existing rows
bin/rails generate uid_attribute:migration Order --backfill

# UUID v4 instead of v7
bin/rails generate uid_attribute:migration Order --uuid-version=4

# Custom column name
bin/rails generate uid_attribute:migration Order --column=public_id

# Force MySQL with binary storage
bin/rails generate uid_attribute:migration Order \
  --adapter=mysql --mysql-storage=binary16

# New table with extra columns and UUID as primary key
bin/rails generate uid_attribute:migration Order \
  --mode=new_table --as-pk \
  --extra-columns name:string total:decimal status:string

# Migrate an existing integer PK to UUID (4 migrations + MIGRATION_PLAN.md)
bin/rails generate uid_attribute:migration Order --mode=promote_to_pk

# NoSQL targets
bin/rails generate uid_attribute:migration Order --adapter=cassandra
bin/rails generate uid_attribute:migration Order --adapter=mongoid
bin/rails generate uid_attribute:migration Order --adapter=dynamodb
bin/rails generate uid_attribute:migration Order --adapter=couchdb
```

### `promote_to_pk` deploy plan

The four generated migrations are individually safe; their sequencing
requires care. A `PROMOTE_<TABLE>_TO_UUID_PK.md` file is written
alongside the migrations documenting:

- Lock implications per step
- Coverage and uniqueness verification SQL
- Heavy-traffic alternatives: `pg_repack` (PostgreSQL),
  `pt-online-schema-change` and `gh-ost` (MySQL)
- Foreign key migration patterns for child tables
- Rollback procedure (step 4 is destructive — restore from backup)

Read the plan before running step 4 in production.

## UUID Versions

| Version | Source                  | When to use                    |
| ------- | ----------------------- | ------------------------------ |
| 7       | `SecureRandom.uuid_v7`  | Default — sortable, indexable  |
| 4       | `SecureRandom.uuid`     | Pure entropy, no timestamp     |

UUID v7 embeds a millisecond Unix timestamp in the leading 48 bits.
Sequential inserts cluster physically in B-tree indexes, avoiding
the index fragmentation that v4 causes at scale.

## Requirements

- Ruby >= 3.4.0 (for `SecureRandom.uuid_v7`, shipped in 3.3+)
- ActiveModel / ActiveSupport >= 7.2 (runtime)
- ActiveRecord >= 7.2 (only for `ActiveRecordIntegration`)

Tested against Ruby 3.4 + 4.0 × ActiveRecord 7.2 + 8.1.

## License

MIT — see LICENSE.
