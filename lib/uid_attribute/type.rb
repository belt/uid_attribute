# frozen_string_literal: true

require "active_model/type"

module UidAttribute
  # ActiveModel custom type for UUID columns.
  #
  # Stores canonical lowercase 8-4-4-4-12 hex form. Rejects values
  # that don't match the RFC 9562 pattern.
  #
  # @example ActiveModel
  #   class Request
  #     include ActiveModel::Attributes
  #     attribute :token, UidAttribute::Type.new
  #   end
  #
  # @example ActiveRecord (auto-registered as :uuid_string via Railtie)
  #   class User < ActiveRecord::Base
  #     attribute :public_id, :uuid_string
  #   end
  #
  class Type < ActiveModel::Type::Value
    def type = :uuid_string

    def cast(value)
      return nil if value.nil?

      str = value.to_s.downcase
      Generator.valid?(str) ? str : nil
    end

    def serialize(value)
      cast(value)
    end

    def deserialize(value)
      cast(value)
    end
  end
end
