# frozen_string_literal: true

require "spec_helper"

RSpec.describe UidAttribute::Type do
  let(:type) { described_class.new }
  let(:valid) { "018f4d9c-7a8b-7000-9b2a-1c3d4e5f6a7b" }

  it "exposes the :uuid_string type symbol" do
    expect(type.type).to eq(:uuid_string)
  end

  describe "#cast" do
    it "passes valid UUIDs through unchanged" do
      expect(type.cast(valid)).to eq(valid)
    end

    it "lowercases mixed-case input" do
      expect(type.cast(valid.upcase)).to eq(valid)
    end

    it "returns nil for invalid input" do
      expect(type.cast("nope")).to be_nil
    end

    it "returns nil for nil" do
      expect(type.cast(nil)).to be_nil
    end
  end

  describe "#serialize / #deserialize" do
    it "round-trips canonical UUIDs" do
      expect(type.deserialize(type.serialize(valid))).to eq(valid)
    end

    it "drops invalid values to nil" do
      expect(type.serialize("nope")).to be_nil
    end
  end
end
