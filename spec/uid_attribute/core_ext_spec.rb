# frozen_string_literal: true

require "spec_helper"
require "uid_attribute/core_ext"

RSpec.describe UidAttribute::CoreExt do
  using UidAttribute::CoreExt

  it "adds String#uuid?" do
    expect("018f4d9c-7a8b-7000-9b2a-1c3d4e5f6a7b".uuid?).to be true
    expect("not-a-uuid".uuid?).to be false
  end

  it "adds String#uuid_version" do
    expect("018f4d9c-7a8b-7000-9b2a-1c3d4e5f6a7b".uuid_version).to eq(7)
    expect("f47ac10b-58cc-4372-a567-0e02b2c3d479".uuid_version).to eq(4)
    expect("nope".uuid_version).to be_nil
  end
end
