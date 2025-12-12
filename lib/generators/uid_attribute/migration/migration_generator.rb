# frozen_string_literal: true

require "rails/generators"
require "rails/generators/named_base"
require "rails/generators/migration"
require "active_record"

module UidAttribute
  module Generators
    # Rails generator that emits production-safe UUID column migrations.
    #
    # Modes:
    #   - add_column     (default) — add a UUID column to an existing table
    #   - new_table      — create a new table with a UUID column
    #   - promote_to_pk  — migrate an integer primary key to UUID
    #
    # Adapters: postgresql, mysql, sqlite (Wave 4 adds cassandra, mongoid).
    #
    # @example
    #   rails g uid_attribute:migration Order
    #   rails g uid_attribute:migration Order --uuid-version=4 --backfill
    #   rails g uid_attribute:migration Order --adapter=mysql --mysql-storage=binary16
    class MigrationGenerator < Rails::Generators::NamedBase
      include Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      MODES = %w[add_column new_table promote_to_pk].freeze
      ADAPTERS = %w[postgresql postgres postgis mysql mysql2 trilogy sqlite sqlite3 cassandra mongoid dynamodb couchdb].freeze
      VERSIONS = [4, 7].freeze
      MYSQL_STORAGE = %w[char36 binary16].freeze
      DEFAULT_BATCH_SIZE = 1_000

      class_option :mode, type: :string, default: "add_column",
        enum: MODES,
        desc: "Migration mode"
      class_option :column, type: :string, default: "uid",
        desc: "UUID column name"
      class_option :uuid_version, type: :numeric, default: 7,
        enum: VERSIONS,
        desc: "UUID version (4 or 7)"
      class_option :backfill, type: :boolean, default: false,
        desc: "Generate companion backfill migration"
      class_option :concurrent, type: :boolean, default: true,
        desc: "Use concurrent index creation (PostgreSQL)"
      class_option :adapter, type: :string,
        enum: ADAPTERS,
        desc: "Force adapter"
      class_option :mysql_storage, type: :string, default: "char36",
        enum: MYSQL_STORAGE,
        desc: "MySQL UUID storage strategy"
      class_option :as_pk, type: :boolean, default: false,
        desc: "Use the UUID column as primary key (new_table mode)"
      class_option :extra_columns, type: :array, default: [],
        banner: "name:type ...",
        desc: "Extra columns for new_table mode (e.g., name:string total:decimal)"

      # Required by Rails::Generators::Migration to interleave timestamps.
      # When emitting multiple migrations in one generator run (e.g., schema +
      # backfill), bump the timestamp to keep them ordered and distinct.
      def self.next_migration_number(dirname)
        if defined?(ActiveRecord) && ActiveRecord.respond_to?(:timestamped_migrations) &&
            ActiveRecord.timestamped_migrations
          @last_migration_number ||= "0"
          candidate = Time.now.utc.strftime("%Y%m%d%H%M%S")
          candidate = (@last_migration_number.to_i + 1).to_s if candidate <= @last_migration_number
          @last_migration_number = candidate
        else
          format("%.3d", current_migration_number(dirname) + 1)
        end
      end

      def create_migration_file
        validate_options!

        case mode
        when "add_column" then emit_add_column_migration
        when "new_table" then emit_new_table_migration
        when "promote_to_pk" then emit_promote_to_pk_migrations
        end
      end

      private

      def emit_add_column_migration
        if adapter == "cassandra"
          template(
            "add_column/cassandra.cql.tt",
            "db/cql_migrate/#{cql_timestamp}_#{add_column_filename}.cql"
          )
          return
        end

        if adapter == "mongoid"
          migration_template(
            "add_column/mongoid.rb.tt",
            "db/mongo_migrate/#{add_column_filename}.rb"
          )
          return
        end

        if adapter == "dynamodb"
          template(
            "add_column/dynamodb.rb.tt",
            "db/dynamodb_migrate/#{cql_timestamp}_#{add_column_filename}.rb"
          )
          return
        end

        if adapter == "couchdb"
          template(
            "add_column/couchdb.rb.tt",
            "db/couchdb_migrate/#{cql_timestamp}_#{add_column_filename}.rb"
          )
          return
        end

        migration_template(
          "add_column/#{adapter_template}.rb.tt",
          "db/migrate/#{add_column_filename}.rb"
        )
        return unless options[:backfill]

        migration_template(
          "backfill/#{adapter_template}.rb.tt",
          "db/migrate/#{backfill_filename}.rb"
        )
      end

      def emit_new_table_migration
        if adapter == "cassandra"
          template(
            "new_table/cassandra.cql.tt",
            "db/cql_migrate/#{cql_timestamp}_#{new_table_filename}.cql"
          )
          return
        end

        if adapter == "mongoid"
          migration_template(
            "new_table/mongoid.rb.tt",
            "db/mongo_migrate/#{new_table_filename}.rb"
          )
          return
        end

        if adapter == "dynamodb"
          template(
            "new_table/dynamodb.rb.tt",
            "db/dynamodb_migrate/#{cql_timestamp}_#{new_table_filename}.rb"
          )
          return
        end

        if adapter == "couchdb"
          template(
            "new_table/couchdb.rb.tt",
            "db/couchdb_migrate/#{cql_timestamp}_#{new_table_filename}.rb"
          )
          return
        end

        migration_template(
          "new_table/#{adapter_template}.rb.tt",
          "db/migrate/#{new_table_filename}.rb"
        )
      end

      def emit_promote_to_pk_migrations
        promote_to_pk_steps.each do |step_key, filename|
          migration_template(
            "promote_to_pk/#{adapter_template}/#{step_key}.rb.tt",
            "db/migrate/#{filename}.rb"
          )
        end

        # Render the deploy plan inside db/migrate so it travels with the
        # migrations. Use Thor's template helper directly (not migration_template,
        # which would prefix a timestamp).
        template(
          "promote_to_pk/#{adapter_template}/MIGRATION_PLAN.md.tt",
          "db/migrate/PROMOTE_#{table_name.upcase}_TO_UUID_PK.md"
        )
      end

      def validate_options!
        # Cassandra, Mongoid, DynamoDB, and CouchDB are supported in
        # add_column and new_table modes only; promote_to_pk is AR-specific.
        if non_relational_adapter? && mode == "promote_to_pk"
          raise Thor::Error,
            "--mode=promote_to_pk is only supported on relational adapters " \
            "(postgresql, mysql, sqlite); not on '#{adapter}'."
        end
      end

      def non_relational_adapter?
        %w[cassandra mongoid dynamodb couchdb].include?(adapter)
      end

      def cassandra_or_mongoid?
        %w[cassandra mongoid].include?(adapter)
      end

      def adapter
        @adapter ||= (options[:adapter] || detect_adapter).to_s.downcase
      end

      # Map a detected adapter (e.g., "PostgreSQL", "Mysql2", "Trilogy") to
      # the canonical template directory name.
      def adapter_template
        case adapter
        when "postgresql", "postgres", "postgis" then "postgresql"
        when "mysql", "mysql2", "trilogy" then "mysql"
        when "sqlite", "sqlite3" then "sqlite"
        else adapter
        end
      end

      def detect_adapter
        return "postgresql" unless defined?(ActiveRecord::Base)

        ActiveRecord::Base.connection_db_config.adapter
      rescue
        "postgresql"
      end

      def column_name
        options[:column]
      end

      def uuid_version
        options[:uuid_version].to_i
      end

      def mode
        options[:mode]
      end

      def concurrent?
        options[:concurrent]
      end

      def mysql_binary16?
        adapter_template == "mysql" && options[:mysql_storage] == "binary16"
      end

      def add_column_filename
        "add_#{column_name}_to_#{table_name}"
      end

      def add_column_class_name
        add_column_filename.camelize
      end

      def backfill_filename
        "backfill_#{column_name}_for_#{table_name}"
      end

      def backfill_class_name
        backfill_filename.camelize
      end

      def new_table_filename
        "create_#{table_name}"
      end

      def new_table_class_name
        new_table_filename.camelize
      end

      def as_pk?
        options[:as_pk]
      end

      # Parse "name:type" pairs from --extra-columns into [[name, type], ...].
      # Defaults to :string when type is omitted.
      def extra_column_pairs
        Array(options[:extra_columns]).filter_map do |spec|
          name, type = spec.to_s.split(":", 2)
          next nil if name.nil? || name.empty?
          [name, type.presence || "string"]
        end
      end

      # Step key → filename for the promote_to_pk migration sequence.
      # Order is stable and matches the deploy plan.
      def promote_to_pk_steps
        {
          "01_add_uid_column" => "01_add_#{column_name}_column_to_#{table_name}",
          "02_backfill_uid" => "02_backfill_#{column_name}_for_#{table_name}",
          "03_add_uid_unique_index" => "03_add_#{column_name}_unique_index_to_#{table_name}",
          "04_swap_primary_key" => "04_swap_#{table_name}_primary_key_to_#{column_name}"
        }
      end

      # ActiveRecord::Migration[X.Y] version stamp matching the loaded Rails.
      def migration_version
        return "7.2" unless defined?(ActiveRecord::Migration)

        major = ActiveRecord::Migration.current_version
        major.to_s
      rescue
        "7.2"
      end

      def batch_size
        DEFAULT_BATCH_SIZE
      end

      # Cassandra-style timestamp: YYYYMMDDHHMMSS, used for ordering CQL files.
      def cql_timestamp
        Time.now.utc.strftime("%Y%m%d%H%M%S")
      end

      # Map AR-style type names to CQL types for cassandra new_table.
      def cql_column_type(ar_type)
        case ar_type.to_s
        when "string", "text" then "text"
        when "integer" then "int"
        when "bigint" then "bigint"
        when "boolean" then "boolean"
        when "decimal", "numeric" then "decimal"
        when "float", "double" then "double"
        when "datetime", "timestamp" then "timestamp"
        when "date" then "date"
        when "binary", "blob" then "blob"
        when "uuid" then "uuid"
        when "timeuuid" then "timeuuid"
        else ar_type.to_s
        end
      end
    end
  end
end
