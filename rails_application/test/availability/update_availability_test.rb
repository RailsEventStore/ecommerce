require "test_helper"

module Availability
  class UpdateAvailabilityTest < InMemoryTestCase
    cover "Availability*"

    def test_availability_updates
      product_id = SecureRandom.uuid
      prepare_product(product_id)

      event_store.publish(Inventory::AvailabilityChanged.new(data: { product_id: product_id, available: 0 }))

      refute Availability.approximately_available?(product_id, 1)

      event_store.publish(Inventory::AvailabilityChanged.new(data: { product_id: product_id, available: 1 }))
      assert Availability.approximately_available?(product_id, 1)
    end

    private

    def event_store
      Rails.configuration.event_store
    end

    def prepare_product(product_id)
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
    end
  end
end

