require "test_helper"

module Orders
  class RegisterProductTest < InMemoryTestCase
    cover "Orders*"

    def test_register_product
      product_id = SecureRandom.uuid
      product_registered = ProductCatalog::ProductRegistered.new(data: { product_id: product_id })
      product_named = ProductCatalog::ProductNamed.new(data: { product_id: product_id, name: "Async Remote" })
      event_store.publish(product_registered)
      event_store.publish(product_named)

      product = Product.find_by_uid(product_id)
      assert product
      assert_equal "Async Remote", product.name
      assert event_store.event_in_stream?(product_registered.event_id, "Orders$all")
      assert event_store.event_in_stream?(product_named.event_id, "Orders$all")
    end

    private

    def event_store
      Rails.configuration.event_store
    end
  end
end
