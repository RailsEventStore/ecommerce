require_relative "../../../infra/lib/infra"
require_relative "product_catalog/commands"
require_relative "product_catalog/product"
require_relative "product_catalog/registration"
require_relative "product_catalog/assign_price_to_product"

module ProductCatalog
  class Configuration
    def initialize(cqrs)
      @cqrs = cqrs
    end

    def call
      @cqrs.register(RegisterProduct, Registration.new)
    end
  end
end
