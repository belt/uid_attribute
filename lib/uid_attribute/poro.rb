# frozen_string_literal: true

module UidAttribute
  # Mixin for Plain Old Ruby Objects — assigns a UUID at #initialize.
  #
  # Use when the host class is not an ActiveRecord model. Requires the
  # host class to expose a reader and writer for the UID attribute
  # (e.g., via attr_accessor).
  #
  # @example
  #   class Job
  #     include UidAttribute::Poro
  #     attr_accessor :uid
  #   end
  #
  #   Job.new.uid  # => "018f4d9c-..."
  #
  # @example Custom attribute + v4
  #   class Job
  #     include UidAttribute::Poro
  #     attr_accessor :public_id
  #     uid_attribute :public_id, version: 4
  #   end
  #
  module Poro
    def self.included(base)
      base.extend(ClassMethods)
      base.singleton_class.attr_accessor :uid_attribute_name, :uid_attribute_version
      base.uid_attribute_name = :uid
      base.uid_attribute_version = Generator::DEFAULT_VERSION
    end

    module ClassMethods
      # Designate the UID attribute and version.
      #
      # @param attr_name [Symbol]
      # @param version [Integer] 4 or 7
      def uid_attribute(attr_name = :uid, version: Generator::DEFAULT_VERSION)
        unless Generator::SUPPORTED_VERSIONS.include?(version)
          raise UnsupportedVersionError.new(version)
        end

        self.uid_attribute_name = attr_name.to_sym
        self.uid_attribute_version = version
      end
    end

    # Hooks the host's #initialize to assign a UUID to {uid_attribute_name}
    # if the slot is currently blank.
    def initialize(*args, **kwargs, &block)
      super
      _assign_uid_if_blank
    end

    private

    def _assign_uid_if_blank
      attr_name = self.class.uid_attribute_name
      _verify_uid_accessors!(attr_name)

      return if !public_send(attr_name).nil? && public_send(attr_name) != ""

      uid = Generator.generate(version: self.class.uid_attribute_version)
      public_send(:"#{attr_name}=", uid)
    end

    def _verify_uid_accessors!(attr_name)
      unless respond_to?(attr_name)
        raise MissingAccessorError.new(self.class, attr_name, :reader)
      end
      unless respond_to?(:"#{attr_name}=")
        raise MissingAccessorError.new(self.class, attr_name, :writer)
      end
    end
  end
end
