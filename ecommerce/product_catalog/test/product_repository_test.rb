require_relative "test_helper"
require_relative "../lib/product_catalog/product_repository_examples"

module ProductCatalog
  class InMemoryProductRepositoryTest < Test
    cover "ProductCatalog::InMemoryProductRepository*"

    include ProductRepositoryExamples.for(-> { InMemoryProductRepository.new })
  end
end
