# frozen_string_literal: true

require "spec_helper"

RSpec.describe UidAttribute::Generator do
  describe ".generate" do
    it "returns a v7 UUID by default" do
      uid = described_class.generate
      expect(described_class.version_of(uid)).to eq(7)
    end

    it "returns a v4 UUID when version: 4" do
      uid = described_class.generate(version: 4)
      expect(described_class.version_of(uid)).to eq(4)
    end

    it "raises UnsupportedVersionError for unknown versions" do
      expect { described_class.generate(version: 1) }
        .to raise_error(UidAttribute::UnsupportedVersionError, /unsupported UUID version/)
    end

    it "produces canonical lowercase 8-4-4-4-12 hex form" do
      uid = described_class.generate
      expect(uid).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/)
    end

    it "produces unique values across many calls" do
      uids = Array.new(1_000) { described_class.generate }
      expect(uids.uniq.size).to eq(1_000)
    end

    it "produces v7 UUIDs that sort by generation order" do
      first = described_class.generate(version: 7)
      sleep 0.005
      second = described_class.generate(version: 7)
      expect(first < second).to be true
    end
  end

  describe ".valid?" do
    it "accepts canonical UUIDs" do
      expect(described_class.valid?("018f4d9c-7a8b-7000-9b2a-1c3d4e5f6a7b")).to be true
    end

    it "accepts uppercase canonical UUIDs" do
      expect(described_class.valid?("018F4D9C-7A8B-7000-9B2A-1C3D4E5F6A7B")).to be true
    end

    it "rejects non-strings" do
      expect(described_class.valid?(nil)).to be false
      expect(described_class.valid?(123)).to be false
    end

    it "rejects malformed strings" do
      expect(described_class.valid?("not-a-uuid")).to be false
      expect(described_class.valid?("018f4d9c-7a8b-7000-9b2a")).to be false
    end

    it "rejects v0 and v8+ (out of supported range)" do
      expect(described_class.valid?("00000000-0000-0000-0000-000000000000")).to be false
      expect(described_class.valid?("018f4d9c-7a8b-8000-9b2a-1c3d4e5f6a7b")).to be false
    end
  end

  describe ".version_of" do
    it "returns the version nibble for valid UUIDs" do
      expect(described_class.version_of("018f4d9c-7a8b-7000-9b2a-1c3d4e5f6a7b")).to eq(7)
      expect(described_class.version_of("f47ac10b-58cc-4372-a567-0e02b2c3d479")).to eq(4)
    end

    it "returns nil for invalid input" do
      expect(described_class.version_of("nope")).to be_nil
      expect(described_class.version_of(nil)).to be_nil
    end
  end
end
