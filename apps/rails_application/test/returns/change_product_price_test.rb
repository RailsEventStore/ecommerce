require "test_helper"

module Returns
  class ChangeProductPriceTest < InMemoryTestCase
    cover "Returns::ChangeProductPrice*"

    def configure(event_store, _command_bus)
      Returns::Configuration.new.call(event_store)
    end

    def test_stores_product_price
      product_id = SecureRandom.uuid

      price_set(product_id, 42)

      assert_equal(42, Product.find_by!(uid: product_id).price)
    end

    def test_updates_existing_product_price
      product_id = SecureRandom.uuid

      price_set(product_id, 42)
      price_set(product_id, 50)

      assert_equal(50, Product.find_by!(uid: product_id).price)
    end

    private

    def price_set(product_id, price)
      event_store.publish(
        Pricing::PriceSet.new(data: { product_id: product_id, price: price })
      )
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
