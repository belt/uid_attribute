# frozen_string_literal: true

require "securerandom"

module UidAttribute
  # Standalone UUID generator and validator — no ActiveRecord dependency.
  #
  # Defaults to UUID v7 (RFC 9562 §5.7) — time-ordered, monotonic,
  # index-friendly. Falls back to v4 (RFC 9562 §5.4) when entropy
  # over time-ordering is preferred.
  #
  # @example Generate a v7 (default)
  #   UidAttribute::Generator.generate
  #   # => "018f4d9c-7a8b-7000-9b2a-1c3d4e5f6a7b"
  #
  # @example Generate a v4
  #   UidAttribute::Generator.generate(version: 4)
  #   # => "f47ac10b-58cc-4372-a567-0e02b2c3d479"
  #
  # @example Validate
  #   UidAttribute::Generator.valid?("not-a-uuid")  # => false
  #
  module Generator
    # RFC 9562 — canonical 8-4-4-4-12 hex form, version nibble 1-7,
    # variant nibble 8/9/a/b (RFC 4122 / 9562 layout).
    UUID_PATTERN = /\A[0-9a-f]{8}-[0-9a-f]{4}-[1-7][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i

    # UUID versions this gem can emit.
    SUPPORTED_VERSIONS = [4, 7].freeze

    # Default version (v7 — sortable, time-ordered, B-tree friendly).
    DEFAULT_VERSION = 7

    # Position of the version nibble in canonical UUID form (after two dashes).
    VERSION_NIBBLE_INDEX = 14

    module_function

    # Generate a fresh UUID string.
    #
    # @param version [Integer] one of {SUPPORTED_VERSIONS} (default {DEFAULT_VERSION})
    # @return [String] canonical lowercase UUID
    # @raise [UnsupportedVersionError] when the version is not supported
    def generate(version: DEFAULT_VERSION)
      case version
      when 4 then SecureRandom.uuid
      when 7 then uuid_v7
      else raise UnsupportedVersionError.new(version)
      end
    end

    # @return [String] a v7 UUID (Ruby 3.3+ ships SecureRandom.uuid_v7)
    def uuid_v7
      SecureRandom.uuid_v7
    end

    # @param str [Object] candidate value
    # @return [Boolean] true iff str is a canonical UUID v1-v7
    def valid?(str)
      str.is_a?(String) && UUID_PATTERN.match?(str)
    end

    # Extract the UUID version nibble.
    #
    # @param str [String] candidate UUID
    # @return [Integer, nil] version (1-7) or nil if invalid
    def version_of(str)
      return nil unless valid?(str)
      str[VERSION_NIBBLE_INDEX].to_i(16)
    end
  end
end
