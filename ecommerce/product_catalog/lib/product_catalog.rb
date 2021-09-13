require_relative "../../../infra/lib/infra"
require_relative "product_catalog/commands"
require_relative "product_catalog/product"
require_relative "product_catalog/product_registration_handler"
require_relative "product_catalog/assign_price_to_product"

module ProductCatalog
  class Configuration
    def initialize(cqrs)
      @cqrs = cqrs
    end

    def call
      @cqrs.register(RegisterProduct, ProductRegistrationHandler.new)
    end
  end
end
