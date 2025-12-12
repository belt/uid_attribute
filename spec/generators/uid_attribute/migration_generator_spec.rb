# frozen_string_literal: true

require "rails/all"
require "ammeter/init"
require "generators/uid_attribute/migration/migration_generator"

RSpec.describe UidAttribute::Generators::MigrationGenerator, type: :generator do
  destination File.expand_path("../../../tmp/generators", __dir__)

  before { prepare_destination }

  def read_migration(pattern)
    path = Dir["#{destination_root}/db/migrate/*#{pattern}.rb"].first
    raise "no migration matched #{pattern}; got: #{Dir["#{destination_root}/db/migrate/*"].inspect}" if path.nil?
    File.read(path)
  end

  shared_examples "an idempotent migration" do |body_pattern|
    it "guards add_column with column_exists?" do
      expect(read_migration(body_pattern)).to include("unless column_exists?(:orders, :uid)")
    end

    it "uses if_not_exists on add_index" do
      expect(read_migration(body_pattern)).to include("if_not_exists: true")
    end

    it "is reversible (down method present)" do
      expect(read_migration(body_pattern)).to match(/def down/)
    end
  end

  describe "add_column mode (default), PostgreSQL adapter, concurrent (default)" do
    before { run_generator ["Order", "--adapter=postgresql"] }

    it "creates the migration file" do
      expect(Dir["#{destination_root}/db/migrate/*add_uid_to_orders.rb"]).not_to be_empty
    end

    it "uses native :uuid column type" do
      expect(read_migration("add_uid_to_orders")).to include("add_column :orders, :uid, :uuid")
    end

    it "uses concurrent index creation" do
      expect(read_migration("add_uid_to_orders")).to include("algorithm: :concurrently")
    end

    it "disables DDL transaction" do
      expect(read_migration("add_uid_to_orders")).to include("disable_ddl_transaction!")
    end

    it_behaves_like "an idempotent migration", "add_uid_to_orders"
  end

  describe "add_column mode, PostgreSQL adapter, --no-concurrent" do
    before { run_generator ["Order", "--adapter=postgresql", "--no-concurrent"] }

    it "omits algorithm: :concurrently" do
      expect(read_migration("add_uid_to_orders")).not_to include("algorithm: :concurrently")
    end

    it "omits disable_ddl_transaction!" do
      expect(read_migration("add_uid_to_orders")).not_to include("disable_ddl_transaction!")
    end
  end

  describe "add_column mode, MySQL adapter, default char36 storage" do
    before { run_generator ["Order", "--adapter=mysql"] }

    it "uses string with limit 36" do
      expect(read_migration("add_uid_to_orders")).to include(":string, limit: 36")
    end

    it "does not emit binary column" do
      expect(read_migration("add_uid_to_orders")).not_to include(":binary, limit: 16")
    end

    it_behaves_like "an idempotent migration", "add_uid_to_orders"
  end

  describe "add_column mode, MySQL adapter, binary16 storage" do
    before { run_generator ["Order", "--adapter=mysql", "--mysql-storage=binary16"] }

    it "uses binary with limit 16" do
      expect(read_migration("add_uid_to_orders")).to include(":binary, limit: 16")
    end
  end

  describe "add_column mode, SQLite adapter" do
    before { run_generator ["Order", "--adapter=sqlite"] }

    it "uses string with limit 36" do
      expect(read_migration("add_uid_to_orders")).to include(":string, limit: 36")
    end

    it "does not include concurrent index syntax" do
      expect(read_migration("add_uid_to_orders")).not_to include("algorithm: :concurrently")
    end

    it_behaves_like "an idempotent migration", "add_uid_to_orders"
  end

  describe "--column option" do
    before { run_generator ["Order", "--adapter=sqlite", "--column=public_id"] }

    it "names the file after the chosen column" do
      expect(read_migration("add_public_id_to_orders"))
        .to include("add_column :orders, :public_id, :string, limit: 36")
    end

    it "names the index after the chosen column" do
      expect(read_migration("add_public_id_to_orders")).to include("index_orders_on_public_id")
    end
  end

  describe "--backfill option, PostgreSQL" do
    before { run_generator ["Order", "--adapter=postgresql", "--backfill"] }

    it "creates a backfill migration alongside the schema migration" do
      expect(Dir["#{destination_root}/db/migrate/*add_uid_to_orders.rb"]).not_to be_empty
      expect(Dir["#{destination_root}/db/migrate/*backfill_uid_for_orders.rb"]).not_to be_empty
    end

    it "references UidAttribute::Generator with the chosen version" do
      backfill = read_migration("backfill_uid_for_orders")
      expect(backfill).to include("UidAttribute::Generator.generate(version: UID_VERSION)")
      expect(backfill).to include("UID_VERSION = 7")
    end

    it "raises IrreversibleMigration on down" do
      expect(read_migration("backfill_uid_for_orders"))
        .to include("raise ActiveRecord::IrreversibleMigration")
    end
  end

  describe "--backfill option, MySQL binary16" do
    before { run_generator ["Order", "--adapter=mysql", "--mysql-storage=binary16", "--backfill"] }

    it "packs UUID string to binary before update" do
      expect(read_migration("backfill_uid_for_orders"))
        .to include(%([uid_str.delete("-")].pack("H*")))
    end
  end

  describe "--uuid-version option" do
    before { run_generator ["Order", "--adapter=postgresql", "--uuid-version=4", "--backfill"] }

    it "writes UID_VERSION = 4 in the backfill migration" do
      expect(read_migration("backfill_uid_for_orders")).to include("UID_VERSION = 4")
    end
  end

  describe "new_table mode, PostgreSQL" do
    before { run_generator ["Order", "--adapter=postgresql", "--mode=new_table"] }

    it "creates a create_orders migration" do
      expect(read_migration("create_orders")).to include("create_table :orders do |t|")
    end

    it "uses native :uuid column" do
      expect(read_migration("create_orders")).to include("t.uuid :uid, null: false")
    end

    it "adds a unique index" do
      expect(read_migration("create_orders")).to include("unique: true")
    end
  end

  describe "new_table mode, PostgreSQL with --as-pk" do
    before { run_generator ["Order", "--adapter=postgresql", "--mode=new_table", "--as-pk"] }

    it "creates table with id: :uuid and gen_random_uuid() default" do
      body = read_migration("create_orders")
      expect(body).to include("id: :uuid")
      expect(body).to include('default: -> { "gen_random_uuid()" }')
    end
  end

  describe "new_table mode, MySQL char36" do
    before { run_generator ["Order", "--adapter=mysql", "--mode=new_table"] }

    it "uses string column with limit 36" do
      expect(read_migration("create_orders")).to include("t.string :uid, limit: 36, null: false")
    end
  end

  describe "new_table mode, MySQL binary16" do
    before { run_generator ["Order", "--adapter=mysql", "--mysql-storage=binary16", "--mode=new_table"] }

    it "uses binary column with limit 16" do
      expect(read_migration("create_orders")).to include("t.binary :uid, limit: 16, null: false")
    end
  end

  describe "new_table mode, MySQL binary16 with --as-pk" do
    before do
      run_generator [
        "Order", "--adapter=mysql", "--mysql-storage=binary16",
        "--mode=new_table", "--as-pk"
      ]
    end

    it "uses binary primary key id" do
      expect(read_migration("create_orders"))
        .to include("t.binary :id, limit: 16, null: false, primary_key: true")
    end
  end

  describe "new_table mode, SQLite" do
    before { run_generator ["Order", "--adapter=sqlite", "--mode=new_table"] }

    it "uses string column with limit 36" do
      expect(read_migration("create_orders")).to include("t.string :uid, limit: 36, null: false")
    end
  end

  describe "new_table mode with --extra-columns" do
    before do
      run_generator [
        "Order", "--adapter=postgresql", "--mode=new_table",
        "--extra-columns", "name:string", "total:decimal", "status:string"
      ]
    end

    it "emits each extra column with the chosen type" do
      body = read_migration("create_orders")
      expect(body).to include("t.string :name")
      expect(body).to include("t.decimal :total")
      expect(body).to include("t.string :status")
    end
  end

  describe "new_table mode with bare extra column (default :string)" do
    before do
      run_generator [
        "Order", "--adapter=postgresql", "--mode=new_table",
        "--extra-columns", "name"
      ]
    end

    it "defaults the type to :string" do
      expect(read_migration("create_orders")).to include("t.string :name")
    end
  end

  describe "unsupported adapters" do
    it "raises Thor::Error for cassandra promote_to_pk" do
      expect {
        run_generator ["Order", "--adapter=cassandra", "--mode=promote_to_pk"]
      }.to raise_error(Thor::Error, /promote_to_pk is only supported on relational adapters/)
    end

    it "raises Thor::Error for mongoid promote_to_pk" do
      expect {
        run_generator ["Order", "--adapter=mongoid", "--mode=promote_to_pk"]
      }.to raise_error(Thor::Error, /promote_to_pk is only supported on relational adapters/)
    end

    it "raises Thor::Error for dynamodb promote_to_pk" do
      expect {
        run_generator ["Order", "--adapter=dynamodb", "--mode=promote_to_pk"]
      }.to raise_error(Thor::Error, /promote_to_pk is only supported on relational adapters/)
    end

    it "raises Thor::Error for couchdb promote_to_pk" do
      expect {
        run_generator ["Order", "--adapter=couchdb", "--mode=promote_to_pk"]
      }.to raise_error(Thor::Error, /promote_to_pk is only supported on relational adapters/)
    end
  end

  describe "Cassandra add_column mode" do
    before { run_generator ["Order", "--adapter=cassandra"] }

    it "creates a .cql file under db/cql_migrate" do
      expect(Dir["#{destination_root}/db/cql_migrate/*add_uid_to_orders.cql"]).not_to be_empty
    end

    it "uses timeuuid for v7 (default)" do
      cql = File.read(Dir["#{destination_root}/db/cql_migrate/*add_uid_to_orders.cql"].first)
      expect(cql).to include("ADD uid timeuuid")
    end

    it "creates a secondary index" do
      cql = File.read(Dir["#{destination_root}/db/cql_migrate/*add_uid_to_orders.cql"].first)
      expect(cql).to include("CREATE INDEX IF NOT EXISTS")
    end
  end

  describe "Cassandra add_column with --uuid-version=4" do
    before { run_generator ["Order", "--adapter=cassandra", "--uuid-version=4"] }

    it "uses uuid (random) instead of timeuuid" do
      cql = File.read(Dir["#{destination_root}/db/cql_migrate/*add_uid_to_orders.cql"].first)
      expect(cql).to include("ADD uid uuid")
      expect(cql).not_to include("ADD uid timeuuid")
    end
  end

  describe "Cassandra new_table mode" do
    before do
      run_generator [
        "Order", "--adapter=cassandra", "--mode=new_table",
        "--extra-columns", "name:string", "total:decimal"
      ]
    end

    it "creates a CREATE TABLE statement" do
      cql = File.read(Dir["#{destination_root}/db/cql_migrate/*create_orders.cql"].first)
      expect(cql).to include("CREATE TABLE IF NOT EXISTS orders")
    end

    it "maps :string to text and :decimal to decimal" do
      cql = File.read(Dir["#{destination_root}/db/cql_migrate/*create_orders.cql"].first)
      expect(cql).to include("name text")
      expect(cql).to include("total decimal")
    end
  end

  describe "Cassandra new_table with --as-pk" do
    before do
      run_generator ["Order", "--adapter=cassandra", "--mode=new_table", "--as-pk"]
    end

    it "uses uid as PRIMARY KEY" do
      cql = File.read(Dir["#{destination_root}/db/cql_migrate/*create_orders.cql"].first)
      expect(cql).to include("PRIMARY KEY (uid)")
    end
  end

  describe "Cassandra new_table CQL type mapping" do
    before do
      run_generator [
        "Order", "--adapter=cassandra", "--mode=new_table",
        "--extra-columns",
        "count:integer", "big:bigint", "active:boolean",
        "amount:float", "started_at:datetime", "born:date",
        "blob_field:binary", "ext_uuid:uuid", "ext_tuid:timeuuid",
        "unknown:custom_type"
      ]
    end

    it "maps each AR-style type to its CQL equivalent" do
      cql = File.read(Dir["#{destination_root}/db/cql_migrate/*create_orders.cql"].first)
      expect(cql).to include("count int")
      expect(cql).to include("big bigint")
      expect(cql).to include("active boolean")
      expect(cql).to include("amount double")
      expect(cql).to include("started_at timestamp")
      expect(cql).to include("born date")
      expect(cql).to include("blob_field blob")
      expect(cql).to include("ext_uuid uuid")
      expect(cql).to include("ext_tuid timeuuid")
      expect(cql).to include("unknown custom_type")
    end
  end

  describe "adapter aliases" do
    {
      "postgres" => "add_column :orders, :uid, :uuid",
      "postgis" => "add_column :orders, :uid, :uuid",
      "mysql2" => ":string, limit: 36",
      "trilogy" => ":string, limit: 36",
      "sqlite3" => ":string, limit: 36"
    }.each do |adapter, fingerprint|
      context adapter do
        before { run_generator ["Order", "--adapter=#{adapter}"] }

        it "emits the canonical template for #{adapter}" do
          expect(read_migration("add_uid_to_orders")).to include(fingerprint)
        end
      end
    end
  end

  describe "Mongoid add_column mode" do
    before { run_generator ["Order", "--adapter=mongoid"] }

    it "creates a Mongoid::Migration under db/mongo_migrate" do
      path = Dir["#{destination_root}/db/mongo_migrate/*add_uid_to_orders.rb"].first
      expect(path).not_to be_nil
      body = File.read(path)
      expect(body).to include("Mongoid::Migration")
    end

    it "backfills via UidAttribute::Generator" do
      path = Dir["#{destination_root}/db/mongo_migrate/*add_uid_to_orders.rb"].first
      expect(File.read(path)).to include("UidAttribute::Generator.generate(version: UID_VERSION)")
    end

    it "creates a unique index on the chosen field" do
      path = Dir["#{destination_root}/db/mongo_migrate/*add_uid_to_orders.rb"].first
      expect(File.read(path)).to include("unique: true")
    end
  end

  describe "Mongoid new_table mode" do
    before { run_generator ["Order", "--adapter=mongoid", "--mode=new_table"] }

    it "creates the collection and a unique index" do
      path = Dir["#{destination_root}/db/mongo_migrate/*create_orders.rb"].first
      expect(path).not_to be_nil
      body = File.read(path)
      expect(body).to include('command(create: "orders")')
      expect(body).to include("unique: true")
    end

    it "drops the collection on rollback" do
      path = Dir["#{destination_root}/db/mongo_migrate/*create_orders.rb"].first
      expect(File.read(path)).to include('Mongoid.default_client["orders"].drop')
    end
  end

  describe "DynamoDB add_column mode" do
    before { run_generator ["Order", "--adapter=dynamodb"] }

    it "creates a Ruby file under db/dynamodb_migrate" do
      path = Dir["#{destination_root}/db/dynamodb_migrate/*add_uid_to_orders.rb"].first
      expect(path).not_to be_nil
    end

    it "issues UpdateTable with a GSI on the uuid attribute" do
      path = Dir["#{destination_root}/db/dynamodb_migrate/*add_uid_to_orders.rb"].first
      body = File.read(path)
      expect(body).to include("update_table")
      expect(body).to include('attribute_name: "uid"')
      expect(body).to include("global_secondary_index_updates")
    end

    it "names the GSI consistently" do
      path = Dir["#{destination_root}/db/dynamodb_migrate/*add_uid_to_orders.rb"].first
      expect(File.read(path)).to include('INDEX_NAME = "orders_uid_index"')
    end
  end

  describe "DynamoDB new_table mode" do
    before { run_generator ["Order", "--adapter=dynamodb", "--mode=new_table"] }

    it "creates a CreateOrders class with create_table call" do
      path = Dir["#{destination_root}/db/dynamodb_migrate/*create_orders.rb"].first
      expect(path).not_to be_nil
      body = File.read(path)
      expect(body).to include("class CreateOrders")
      expect(body).to include("client.create_table")
      expect(body).to include('billing_mode: "PAY_PER_REQUEST"')
    end

    it "uses GSI for non-PK uuid (default)" do
      path = Dir["#{destination_root}/db/dynamodb_migrate/*create_orders.rb"].first
      expect(File.read(path)).to include("global_secondary_indexes")
    end
  end

  describe "DynamoDB new_table mode with --as-pk" do
    before { run_generator ["Order", "--adapter=dynamodb", "--mode=new_table", "--as-pk"] }

    it "uses uuid as the partition key without a GSI" do
      body = File.read(Dir["#{destination_root}/db/dynamodb_migrate/*create_orders.rb"].first)
      expect(body).to include('attribute_name: "uid"')
      expect(body).to include('key_type: "HASH"')
      expect(body).not_to include("global_secondary_indexes")
    end
  end

  describe "CouchDB add_column mode" do
    before { run_generator ["Order", "--adapter=couchdb"] }

    it "creates a Ruby file under db/couchdb_migrate" do
      path = Dir["#{destination_root}/db/couchdb_migrate/*add_uid_to_orders.rb"].first
      expect(path).not_to be_nil
    end

    it "backfills via UidAttribute::Generator and creates a Mango index" do
      body = File.read(Dir["#{destination_root}/db/couchdb_migrate/*add_uid_to_orders.rb"].first)
      expect(body).to include("UidAttribute::Generator.generate(version: UID_VERSION)")
      expect(body).to include("_index")
      expect(body).to include('fields: ["uid"]')
    end
  end

  describe "CouchDB new_table mode" do
    before { run_generator ["Order", "--adapter=couchdb", "--mode=new_table"] }

    it "PUTs to create the database and POSTs to create the index" do
      body = File.read(Dir["#{destination_root}/db/couchdb_migrate/*create_orders.rb"].first)
      expect(body).to include("Net::HTTP::Put")
      expect(body).to include("_index")
      expect(body).to include('DB_NAME = "orders"')
    end
  end

  describe "promote_to_pk mode, PostgreSQL" do
    before { run_generator ["Order", "--adapter=postgresql", "--mode=promote_to_pk"] }

    it "creates four numbered migrations" do
      %w[
        01_add_uid_column_to_orders
        02_backfill_uid_for_orders
        03_add_uid_unique_index_to_orders
        04_swap_orders_primary_key_to_uid
      ].each do |name|
        expect(Dir["#{destination_root}/db/migrate/*#{name}.rb"]).not_to be_empty,
          "expected migration matching #{name}"
      end
    end

    it "creates a MIGRATION_PLAN.md scoped to the table" do
      expect(File.exist?("#{destination_root}/db/migrate/PROMOTE_ORDERS_TO_UUID_PK.md")).to be true
    end

    it "step 1 uses :uuid column type" do
      body = read_migration("01_add_uid_column_to_orders")
      expect(body).to include("add_column :orders, :uid, :uuid")
    end

    it "step 1 disables DDL transaction by default (concurrent path)" do
      expect(read_migration("01_add_uid_column_to_orders")).to include("disable_ddl_transaction!")
    end

    it "step 3 emits concurrent index and NOT NULL flip" do
      body = read_migration("03_add_uid_unique_index_to_orders")
      expect(body).to include("algorithm: :concurrently")
      expect(body).to include("change_column_null :orders, :uid, false")
    end

    it "step 4 raises IrreversibleMigration" do
      expect(read_migration("04_swap_orders_primary_key_to_uid"))
        .to include("raise ActiveRecord::IrreversibleMigration")
    end

    it "MIGRATION_PLAN.md mentions pg_repack for heavy traffic" do
      plan = File.read("#{destination_root}/db/migrate/PROMOTE_ORDERS_TO_UUID_PK.md")
      expect(plan).to include("pg_repack")
      expect(plan).to include("Foreign keys")
    end
  end

  describe "promote_to_pk mode, MySQL char36" do
    before { run_generator ["Order", "--adapter=mysql", "--mode=promote_to_pk"] }

    it "step 1 uses string limit 36" do
      expect(read_migration("01_add_uid_column_to_orders")).to include(":string, limit: 36")
    end

    it "step 4 issues DROP/ADD PRIMARY KEY" do
      body = read_migration("04_swap_orders_primary_key_to_uid")
      expect(body).to include("DROP PRIMARY KEY")
      expect(body).to include("ADD PRIMARY KEY (`uid`)")
    end

    it "MIGRATION_PLAN.md mentions pt-online-schema-change and gh-ost" do
      plan = File.read("#{destination_root}/db/migrate/PROMOTE_ORDERS_TO_UUID_PK.md")
      expect(plan).to include("pt-online-schema-change")
      expect(plan).to include("gh-ost")
    end
  end

  describe "promote_to_pk mode, MySQL binary16" do
    before do
      run_generator [
        "Order", "--adapter=mysql", "--mysql-storage=binary16",
        "--mode=promote_to_pk"
      ]
    end

    it "step 1 uses binary limit 16" do
      expect(read_migration("01_add_uid_column_to_orders")).to include(":binary, limit: 16")
    end

    it "step 2 packs UUID strings to binary" do
      expect(read_migration("02_backfill_uid_for_orders"))
        .to include(%([uid_str.delete("-")].pack("H*")))
    end
  end

  describe "promote_to_pk mode, SQLite" do
    before { run_generator ["Order", "--adapter=sqlite", "--mode=promote_to_pk"] }

    it "step 4 uses table-rebuild pattern" do
      body = read_migration("04_swap_orders_primary_key_to_uid")
      expect(body).to include("CREATE TABLE orders_new")
      expect(body).to include("ALTER TABLE orders_new RENAME TO orders")
    end

    it "MIGRATION_PLAN.md states SQLite has no online DDL" do
      plan = File.read("#{destination_root}/db/migrate/PROMOTE_ORDERS_TO_UUID_PK.md")
      expect(plan).to include("SQLite has no online DDL")
    end
  end
end
