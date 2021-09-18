require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../lib/product_catalog"

module ProductCatalog
  class Test < Infra::InMemoryTest
    attr_reader :product_repository

    def before_setup
      super
      @product_repository = InMemoryProductRepository.new
      Configuration.new(product_repository).call(event_store, command_bus)
    end
  end
end
