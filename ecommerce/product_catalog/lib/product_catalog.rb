require "infra"
require_relative "product_catalog/commands"
require_relative "product_catalog/product"
require_relative "product_catalog/in_memory_product_repository"
require_relative "product_catalog/registration"
require_relative "product_catalog/assign_price_to_product"

module ProductCatalog
  class Configuration
    def initialize(product_repository = InMemoryProductRepository.new)
      @product_repository = product_repository
    end

    def call(event_store, command_bus)
      cqrs = Infra::Cqrs.new(event_store, command_bus)
      cqrs.register(RegisterProduct, Registration.new(@product_repository))
    end
  end
end
