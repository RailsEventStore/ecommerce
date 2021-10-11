require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../lib/pricing"
require_relative "../../product_catalog/lib/product_catalog"

module Pricing
  class Test < Infra::InMemoryTest
    attr_reader :product_repository

    def before_setup
      super
      @product_repository = ProductCatalog::InMemoryProductRepository.new
      [
        Configuration.new,
        ProductCatalog::Configuration.new(product_repository)
      ].each { |c| c.call(cqrs) }
      cqrs.subscribe(
        ProductCatalog::AssignPriceToProduct.new(product_repository),
        [Pricing::PriceSet]
      )
    end
  end
end
