require_relative "../../../infra/lib/infra"
require_relative "product_catalog/commands"
require_relative "product_catalog/product"
require_relative "product_catalog/in_memory_product_repository"
require_relative "product_catalog/registration"
require_relative "product_catalog/assign_price_to_product"

module ProductCatalog
  class Configuration
    def initialize(cqrs, product_repository = InMemoryProductRepository.new)
      @cqrs = cqrs
      @product_repository = product_repository
    end

    def call
      @cqrs.register(RegisterProduct, Registration.new(@product_repository))
    end
  end
end
