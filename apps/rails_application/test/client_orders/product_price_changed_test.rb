require "test_helper"

module ClientOrders
  class ProductPriceChangedTest < InMemoryTestCase
    cover "ClientOrders*"

    def configure(event_store, _command_bus)
      ClientOrders::Configuration.new.call(event_store)
    end

    def test_reflects_change
      product_id = prepare_product
      unchanged_product_id = prepare_product

      event_store.publish(Pricing::PriceSet.new(data: { product_id: product_id, price: 100 }))

      assert_equal 100, Product.find_by_uid(product_id).price
      assert_equal 50, Product.find_by_uid(unchanged_product_id).price
    end

    private

    def prepare_product
      product_id = SecureRandom.uuid
      event_store.publish(ProductCatalog::ProductRegistered.new(data: { product_id: product_id }))
      event_store.publish(ProductCatalog::ProductNamed.new(data: { product_id: product_id, name: "test" }))
      event_store.publish(Pricing::PriceSet.new(data: { product_id: product_id, price: 50 }))
      product_id
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
