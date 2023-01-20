require "test_helper"

module Availability
  class UpdateAvailabilityTest < InMemoryTestCase
    cover "Availability*"

    def test_availability_updates
      product_id = SecureRandom.uuid
      prepare_product(product_id)

      event_store.publish(Inventory::AvailabilityChanged.new(data: { product_id: product_id, available: 0 }))

      product = Availability::Product.find_by(uid: product_id)
      assert_equal 0, product.available

      event_store.publish(Inventory::AvailabilityChanged.new(data: { product_id: product_id, available: 1 }))
      product.reload
      assert_equal 1, product.available
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
      Sidekiq::Job.drain_all
    end
  end
end

