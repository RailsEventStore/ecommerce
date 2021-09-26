require "test_helper"
require_relative "../../ecommerce/product_catalog/lib/product_catalog/product_repository_examples"

class ProductRepositoryTest < ActiveSupport::TestCase
  include ProductCatalog::ProductRepositoryExamples.for(
            -> { Ecommerce::ProductRepository.new }
          )

  def setup
    super
    Ecommerce::ProductRepository::Record.delete_all
  end
end
