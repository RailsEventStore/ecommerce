require "test_helper"

module ClientOrders
  class ProductRegisteredTest < InMemoryTestCase
    cover "ClientOrders*"

    def configure(event_store, _command_bus)
      ClientOrders::Configuration.new.call(event_store)
    end

    def test_reflects_change
      product_id = SecureRandom.uuid

      event_store.publish(ProductCatalog::ProductRegistered.new(data: { product_id: product_id }))

      assert_equal(product_id, Product.find_by_uid(product_id).uid)
    end

    private

    def event_store
      Rails.configuration.event_store
    end

  end
end
