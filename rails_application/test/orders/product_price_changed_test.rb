require "test_helper"

module Orders
  class ProductPriceChangedTest < InMemoryTestCase
    cover "Orders*"

    def test_reflects_change
      product_id = prepare_product
      unchanged_product_id = prepare_product

      run_command(Pricing::SetPrice.new(product_id: product_id, price: 100))

      assert_equal 100, Product.find_by_uid(product_id).price
      assert_equal 50, Product.find_by_uid(unchanged_product_id).price
      price_events = event_store.read.of_type([Pricing::PriceSet]).to_a.first
      assert event_store.event_in_stream?(price_events.event_id, "Orders$all")
    end

    def test_race_condition
      product_id = SecureRandom.uuid
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 100))
      run_command(ProductCatalog::RegisterProduct.new(product_id: product_id))

      assert_equal 100, Product.find_by_uid(product_id).price
    end

    private

    def event_store
      Rails.configuration.event_store
    end

    def prepare_product
      product_id = SecureRandom.uuid
      run_command(
        ProductCatalog::RegisterProduct.new(
          product_id: product_id,
          )
      )
      run_command(
        ProductCatalog::NameProduct.new(
          product_id: product_id,
          name: "test"
        )
      )
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 50))

      product_id
    end
  end
end
