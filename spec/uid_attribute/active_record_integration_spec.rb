# frozen_string_literal: true

require "spec_helper"
require "support/active_record"

RSpec.describe UidAttribute::ActiveRecordIntegration do
  before(:all) do
    Object.send(:remove_const, :Order) if defined?(Order)
    Object.send(:remove_const, :Ticket) if defined?(Ticket)
    Object.send(:remove_const, :UnrelatedModel) if defined?(UnrelatedModel)

    eval <<~RUBY, binding, __FILE__, __LINE__ + 1 # rubocop:disable Security/Eval
      class Order < ActiveRecord::Base
        include UidAttribute::ActiveRecordIntegration
      end

      class Ticket < ActiveRecord::Base
        include UidAttribute::ActiveRecordIntegration
        uid_attribute :public_id, version: 4
      end

      class UnrelatedModel < ActiveRecord::Base
        # No uid/uuid column — mixin should be a no-op.
        include UidAttribute::ActiveRecordIntegration
      end
    RUBY
  end

  after(:all) do
    Object.send(:remove_const, :Order) if defined?(Order)
    Object.send(:remove_const, :Ticket) if defined?(Ticket)
    Object.send(:remove_const, :UnrelatedModel) if defined?(UnrelatedModel)
  end

  describe "convention-driven detection" do
    it "auto-detects :uid and assigns v7 on save" do
      order = Order.new(name: "test")
      order.save!
      expect(UidAttribute::Generator.version_of(order.uid)).to eq(7)
    end

    it "validates presence" do
      kinds = Order.validators_on(:uid).map(&:kind)
      expect(kinds).to include(:presence)
    end

    it "preserves an explicitly assigned UID" do
      preset = UidAttribute::Generator.generate
      order = Order.new(name: "test", uid: preset)
      order.save!
      expect(order.uid).to eq(preset)
    end

    it "does nothing when no uid/uuid column exists" do
      expect(UnrelatedModel.uid_attribute_name).to be_nil
      expect(UnrelatedModel.create!(name: "free")).to be_persisted
    end
  end

  describe "explicit configuration" do
    it "uses the named attribute and version" do
      ticket = Ticket.new(name: "test")
      ticket.save!
      expect(UidAttribute::Generator.version_of(ticket.public_id)).to eq(4)
    end

    it "raises on unsupported versions" do
      expect {
        Class.new(ActiveRecord::Base) do
          self.table_name = "orders"
          include UidAttribute::ActiveRecordIntegration

          uid_attribute :uid, version: 1
        end
      }.to raise_error(UidAttribute::UnsupportedVersionError)
    end
  end
end
