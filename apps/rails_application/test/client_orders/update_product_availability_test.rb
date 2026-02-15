require "test_helper"

module ClientOrders
  class UpdateProductAvailabilityTest < InMemoryTestCase
     cover "ClientOrders*"

    def configure(event_store, _command_bus)
      ClientOrders::Configuration.new.call(event_store)
    end

    def test_reflects_change
      product_id = prepare_product
      other_product_id = prepare_product

      assert_changes("Product.find_by_uid(product_id).available?", from: true, to: false) do
        ProductHandlers::UpdateProductAvailability.new.call(availability_changed_event(product_id, -1))
      end

      assert_changes("Product.find_by_uid(product_id).available?", from: false, to: true) do
        ProductHandlers::UpdateProductAvailability.new.call(availability_changed_event(product_id, 10))
      end

      assert_changes("Product.find_by_uid(product_id).available?", from: true, to: false) do
        ProductHandlers::UpdateProductAvailability.new.call(availability_changed_event(product_id, 0))
      end

      assert Product.find_by_uid(other_product_id).available?
    end

    private

    def prepare_product
      product_id = SecureRandom.uuid
      event_store.publish(ProductCatalog::ProductRegistered.new(data: { product_id: product_id }))
      event_store.publish(ProductCatalog::ProductNamed.new(data: { product_id: product_id, name: "test" }))
      event_store.publish(Pricing::PriceSet.new(data: { product_id: product_id, price: 50 }))
      product_id
    end

    def availability_changed_event(product_id, available)
      Inventory::AvailabilityChanged.new(data: { product_id: product_id, available: available })
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
