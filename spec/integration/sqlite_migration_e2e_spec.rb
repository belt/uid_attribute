# frozen_string_literal: true

require "rails/all"
require "ammeter/init"
require "active_record"
require "generators/uid_attribute/migration/migration_generator"

# End-to-end integration tests: generate the migration, load it into Ruby,
# run it against an in-memory SQLite database, and assert on the resulting
# schema. Catches template breakage that string-matching specs miss.
RSpec.describe UidAttribute::Generators::MigrationGenerator,
  type: :generator, integration: true do
  destination File.expand_path("../../tmp/integration", __dir__)

  before { prepare_destination }

  # The shared support harness (spec/support/active_record.rb) loads tables
  # into ActiveRecord::Base's connection at suite-load. These integration
  # examples mutate that schema (drop/create tables, run migrations), so we
  # restore the harness state after each example to keep test order safe.
  after do
    load File.expand_path("../support/active_record.rb", __dir__)
  end

  let(:connection) do
    ActiveRecord::Base.establish_connection(
      adapter: "sqlite3",
      database: ":memory:"
    )
    ActiveRecord::Base.connection
  end

  # Load the most recent migration matching the pattern, find its class
  # by name (parsed from file source — Migration.descendants is polluted
  # by Rails compat shims), and migrate it.
  def run_generated_migration(filename_pattern, direction: :up)
    path = Dir["#{destination_root}/db/migrate/*#{filename_pattern}.rb"].first
    raise "no migration matched #{filename_pattern}" if path.nil?

    source = File.read(path)
    class_name = source[/^class\s+(\w+)\s*</, 1]
    raise "could not parse migration class from #{path}" if class_name.nil?

    load(path)
    klass = Object.const_get(class_name)
    klass.suppress_messages { klass.migrate(direction) }
    klass
  end

  describe "add_column mode" do
    before do
      connection.create_table :orders, force: true do |t|
        t.string :name
      end
    end

    it "adds the uid column to an existing orders table" do
      run_generator ["Order", "--adapter=sqlite"]
      run_generated_migration("add_uid_to_orders")

      column = connection.columns(:orders).find { |c| c.name == "uid" }
      expect(column).not_to be_nil
      expect(column.sql_type.downcase).to include("varchar")
    end

    it "creates a unique index named index_orders_on_uid" do
      run_generator ["Order", "--adapter=sqlite"]
      run_generated_migration("add_uid_to_orders")

      idx = connection.indexes(:orders).find { |i| i.name == "index_orders_on_uid" }
      expect(idx).not_to be_nil
      expect(idx.unique).to be true
      expect(idx.columns).to eq(["uid"])
    end

    it "is reversible (down removes the column and index)" do
      run_generator ["Order", "--adapter=sqlite"]
      klass = run_generated_migration("add_uid_to_orders")
      klass.suppress_messages { klass.migrate(:down) }

      expect(connection.columns(:orders).map(&:name)).not_to include("uid")
      expect(connection.indexes(:orders).map(&:name)).not_to include("index_orders_on_uid")
    end

    it "is idempotent on re-run" do
      run_generator ["Order", "--adapter=sqlite"]
      klass = run_generated_migration("add_uid_to_orders")

      expect {
        klass.suppress_messages { klass.migrate(:up) }
      }.not_to raise_error
    end
  end

  describe "add_column with --backfill" do
    it "backfills NULL uid values with valid UUIDv7 strings" do
      connection.create_table :orders, force: true do |t|
        t.string :name
      end
      connection.execute("INSERT INTO orders (name) VALUES ('a'), ('b'), ('c')")

      run_generator ["Order", "--adapter=sqlite", "--backfill"]
      run_generated_migration("add_uid_to_orders")
      run_generated_migration("backfill_uid_for_orders")

      uids = connection.execute("SELECT uid FROM orders").map { |r| r["uid"] }
      expect(uids).to all(match(/\A[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/))
      expect(uids.uniq.size).to eq(3)
    end
  end

  describe "new_table mode" do
    before do
      connection.drop_table :orders if connection.table_exists?(:orders)
    end

    it "creates the orders table with uid column, indexes, and timestamps" do
      run_generator ["Order", "--adapter=sqlite", "--mode=new_table"]
      run_generated_migration("create_orders")

      expect(connection.table_exists?(:orders)).to be true
      column_names = connection.columns(:orders).map(&:name)
      expect(column_names).to include("uid", "created_at", "updated_at")

      indexes = connection.indexes(:orders).map(&:name)
      expect(indexes).to include("index_orders_on_uid")
    end

    it "honours --extra-columns" do
      run_generator [
        "Order", "--adapter=sqlite", "--mode=new_table",
        "--extra-columns", "name:string", "total:decimal"
      ]
      run_generated_migration("create_orders")

      types = connection.columns(:orders).each_with_object({}) do |c, h|
        h[c.name] = c.sql_type.downcase
      end
      expect(types["name"]).to include("varchar")
      expect(types["total"]).to include("decimal")
    end
  end

  describe "promote_to_pk mode" do
    it "runs steps 1-3 in sequence on a populated table" do
      connection.create_table :orders, force: true do |t|
        t.string :name
      end
      connection.execute("INSERT INTO orders (name) VALUES ('a'), ('b')")

      run_generator ["Order", "--adapter=sqlite", "--mode=promote_to_pk"]

      run_generated_migration("01_add_uid_column_to_orders")
      run_generated_migration("02_backfill_uid_for_orders")
      run_generated_migration("03_add_uid_unique_index_to_orders")

      uids = connection.execute("SELECT uid FROM orders").map { |r| r["uid"] }
      expect(uids).to all(match(/\A[0-9a-f-]{36}\z/))
      expect(uids.uniq.size).to eq(2)

      uid_col = connection.columns(:orders).find { |c| c.name == "uid" }
      expect(uid_col.null).to be false

      idx = connection.indexes(:orders).find { |i| i.name == "index_orders_on_uid_unique" }
      expect(idx).not_to be_nil
      expect(idx.unique).to be true
    end
  end
end
