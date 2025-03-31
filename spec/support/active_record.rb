# frozen_string_literal: true

require "active_record"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

ActiveRecord::Schema.define do
  create_table :orders, force: true do |t|
    t.string :uid
    t.string :name
  end

  create_table :tickets, force: true do |t|
    t.string :public_id
    t.string :name
  end

  create_table :unrelated_models, force: true do |t|
    t.string :name
  end
end
