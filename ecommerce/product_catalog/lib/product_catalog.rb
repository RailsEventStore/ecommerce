require "infra"
require_relative "product_catalog/commands"
require_relative "product_catalog/product"
require_relative "product_catalog/in_memory_product_repository"
require_relative "product_catalog/registration"

module ProductCatalog

  class ProductRegistered < Infra::Event
    attribute :product_id, Infra::Types::UUID
    attribute :name,       Infra::Types::String
  end

  class Configuration
    def call(cqrs)
      cqrs.register(RegisterProduct, Registration.new(cqrs))
    end
  end
end
