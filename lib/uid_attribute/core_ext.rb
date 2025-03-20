# frozen_string_literal: true

require_relative "generator"

module UidAttribute
  # Opt-in refinements for String and Symbol UUID predicates.
  #
  # Lexically scoped — applies only in files that opt in with
  # `using UidAttribute::CoreExt`. No global monkey-patching.
  #
  # @example
  #   require "uid_attribute/core_ext"
  #   using UidAttribute::CoreExt
  #
  #   "018f4d9c-7a8b-7000-9b2a-1c3d4e5f6a7b".uuid?         # => true
  #   "018f4d9c-7a8b-7000-9b2a-1c3d4e5f6a7b".uuid_version  # => 7
  #   "not-a-uuid".uuid?                                    # => false
  #
  module CoreExt
    refine String do
      # @return [Boolean] true iff this string is a canonical UUID
      def uuid?
        UidAttribute::Generator.valid?(self)
      end

      # @return [Integer, nil] UUID version, or nil if not a valid UUID
      def uuid_version
        UidAttribute::Generator.version_of(self)
      end
    end
  end
end
