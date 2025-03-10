# frozen_string_literal: true

require_relative "uid_attribute/version"
require_relative "uid_attribute/generator"
require_relative "uid_attribute/error"

# UidAttribute — auto-assign UUIDs (v4 / v7) to PORO and ActiveRecord
# attributes. Defaults to UUID v7 per RFC 9562 — time-ordered and
# index-friendly.
#
# @example PORO
#   class Job
#     include UidAttribute::Poro
#     attr_accessor :uid
#   end
#
#   Job.new.uid  # => "018f4d9c-7a8b-7000-9b2a-1c3d4e5f6a7b"
#
# @example ActiveRecord
#   class Order < ActiveRecord::Base
#     include UidAttribute::ActiveRecordIntegration
#   end
#
# @example Generator only
#   UidAttribute::Generator.generate              # => v7
#   UidAttribute::Generator.generate(version: 4)  # => v4
#
module UidAttribute
  # Load on demand — no hard ActiveRecord dependency at require time.
  autoload :ActiveRecordIntegration, "uid_attribute/active_record_integration"
  autoload :CoreExt, "uid_attribute/core_ext"
  autoload :Poro, "uid_attribute/poro"
  autoload :Type, "uid_attribute/type"
end

require_relative "uid_attribute/railtie" if defined?(Rails::Railtie)
