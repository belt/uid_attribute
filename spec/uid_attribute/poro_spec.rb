# frozen_string_literal: true

require "spec_helper"

RSpec.describe UidAttribute::Poro do
  let(:default_class) do
    Class.new do
      include UidAttribute::Poro

      attr_accessor :uid
    end
  end

  let(:custom_class) do
    Class.new do
      include UidAttribute::Poro

      attr_accessor :public_id
      uid_attribute :public_id, version: 4
    end
  end

  let(:read_only_class) do
    Class.new do
      include UidAttribute::Poro

      attr_reader :uid
    end
  end

  it "auto-assigns a v7 UUID to :uid by default" do
    instance = default_class.new
    expect(UidAttribute::Generator.version_of(instance.uid)).to eq(7)
  end

  it "honors a custom attribute and version" do
    instance = custom_class.new
    expect(UidAttribute::Generator.version_of(instance.public_id)).to eq(4)
  end

  it "raises MissingAccessorError when the writer is missing" do
    expect { read_only_class.new }
      .to raise_error(UidAttribute::MissingAccessorError, /writer/)
  end

  it "rejects unsupported UUID versions" do
    expect {
      Class.new do
        include UidAttribute::Poro

        attr_accessor :uid
        uid_attribute :uid, version: 1
      end
    }.to raise_error(UidAttribute::UnsupportedVersionError)
  end

  it "preserves a UID set during initialize" do
    klass = Class.new do
      include UidAttribute::Poro

      attr_accessor :uid

      def initialize(uid: nil)
        @uid = uid
        super()
      end
    end

    preset = "018f4d9c-7a8b-7000-9b2a-1c3d4e5f6a7b"
    instance = klass.new(uid: preset)
    expect(instance.uid).to eq(preset)
  end
end
