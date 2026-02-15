require "test_helper"

module Orders
  class ProductPriceChangedTest < InMemoryTestCase
    cover "Orders*"

    def configure(event_store, _command_bus)
      Orders::Configuration.new.call(event_store)
    end

    def test_reflects_change
      product_id = prepare_product
      unchanged_product_id = prepare_product

      event_store.publish(Pricing::PriceSet.new(data: { product_id: product_id, price: 100 }))

      assert_equal 100, Product.find_by_uid(product_id).price
      assert_equal 50, Product.find_by_uid(unchanged_product_id).price
      price_events = event_store.read.of_type([Pricing::PriceSet]).to_a.first
      assert event_store.event_in_stream?(price_events.event_id, "Orders$all")
    end

    private

    def event_store
      Rails.configuration.event_store
    end

    def prepare_product
      product_id = SecureRandom.uuid
      event_store.publish(
        ProductCatalog::ProductRegistered.new(
          data: { product_id: product_id }
        )
      )
      event_store.publish(
        ProductCatalog::ProductNamed.new(
          data: { product_id: product_id, name: "test" }
        )
      )
      event_store.publish(Pricing::PriceSet.new(data: { product_id: product_id, price: 50 }))

      product_id
    end
  end
end
