# frozen_string_literal: true

require "active_support/concern"

module UidAttribute
  # Auto-assigns a UUID to a designated attribute on instantiation.
  #
  # Convention over configuration: detects `:uid` or `:uuid` columns,
  # or the user names one explicitly with `uid_attribute :my_id`.
  #
  # @example Convention-driven (column named `uid` or `uuid`)
  #   class Order < ActiveRecord::Base
  #     include UidAttribute::ActiveRecordIntegration
  #   end
  #
  #   Order.new.uid  # => "018f4d9c-7a8b-7000-..." (v7 by default)
  #
  # @example Explicit attribute and version
  #   class Order < ActiveRecord::Base
  #     include UidAttribute::ActiveRecordIntegration
  #     uid_attribute :public_id, version: 4
  #   end
  #
  module ActiveRecordIntegration
    extend ActiveSupport::Concern

    DEFAULT_CANDIDATES = %i[uid uuid].freeze
    private_constant :DEFAULT_CANDIDATES

    included do
      _auto_install_uid_attribute
    end

    class_methods do
      # Designate the UID attribute and configure the gem.
      #
      # @param attr_name [Symbol] column name to populate
      # @param version [Integer] UUID version (4 or 7)
      # @param validate [Boolean] install presence + uniqueness validators
      # @return [void]
      def uid_attribute(attr_name = :uid, version: Generator::DEFAULT_VERSION, validate: true)
        unless Generator::SUPPORTED_VERSIONS.include?(version)
          raise UnsupportedVersionError.new(version)
        end

        self.uid_attribute_name = attr_name.to_sym
        self.uid_attribute_version = version

        _install_uid_validators(attr_name) if validate
        _install_uid_callback(attr_name)
      end

      # @api private
      def _auto_install_uid_attribute
        class_attribute :uid_attribute_name, instance_writer: false
        class_attribute :uid_attribute_version, instance_writer: false

        detected = DEFAULT_CANDIDATES.find { |name| _column_or_attribute?(name) }
        uid_attribute(detected) if detected
      end

      # @api private
      def _column_or_attribute?(name)
        return true if respond_to?(:column_names) && column_names.include?(name.to_s)
        attribute_names.include?(name.to_s) if respond_to?(:attribute_names)
      end

      # @api private
      def _install_uid_validators(attr_name)
        validates attr_name, presence: true
        validates attr_name, uniqueness: true if respond_to?(:validates_uniqueness_of)
      end

      # @api private
      def _install_uid_callback(attr_name)
        before_validation(on: :create) do
          if public_send(attr_name).blank?
            uid = Generator.generate(version: self.class.uid_attribute_version)
            public_send(:"#{attr_name}=", uid)
          end
        end
      end
    end
  end
end
