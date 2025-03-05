# frozen_string_literal: true

module UidAttribute
  # Base error class for UidAttribute.
  class Error < StandardError; end

  # Raised when an unsupported UUID version is requested.
  class UnsupportedVersionError < Error
    attr_reader :version

    def initialize(version)
      @version = version
      supported = Generator::SUPPORTED_VERSIONS.join(", ")
      super("unsupported UUID version: #{version.inspect} (supported: #{supported})")
    end
  end

  # Raised when the including class lacks a reader or writer for the UID attribute.
  class MissingAccessorError < Error
    attr_reader :klass, :attr_name, :kind

    def initialize(klass, attr_name, kind)
      @klass = klass
      @attr_name = attr_name
      @kind = kind
      method_name = (kind == :writer) ? "#{attr_name}=" : attr_name.to_s
      super("#{klass} must define ##{method_name} (#{kind}) for UidAttribute")
    end
  end
end
