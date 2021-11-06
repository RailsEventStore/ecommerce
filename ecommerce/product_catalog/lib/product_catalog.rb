require "infra"
require_relative "product_catalog/commands"
require_relative "product_catalog/product"
require_relative "product_catalog/in_memory_product_repository"
require_relative "product_catalog/registration"

module ProductCatalog
  class Configuration
    def initialize(product_repository = InMemoryProductRepository.new)
      @product_repository = product_repository
    end

    def call(cqrs)
      cqrs.register(RegisterProduct, Registration.new(@product_repository))
    end
  end
end
