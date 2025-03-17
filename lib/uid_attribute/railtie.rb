# frozen_string_literal: true

require "rails/railtie"

module UidAttribute
  # Rails integration: registers the :uuid_string type with ActiveRecord.
  class Railtie < Rails::Railtie
    initializer "uid_attribute.register_type" do
      ActiveSupport.on_load(:active_record) do
        require "uid_attribute/type"
        ActiveRecord::Type.register(:uuid_string, UidAttribute::Type)
      end
    end
  end
end
