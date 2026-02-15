require "test_helper"

module PublicOffer
  class ProductTest < InMemoryTestCase
    cover "PublicOffer*"

    def configure(event_store, _command_bus)
      PublicOffer::Configuration.new(event_store).call
    end

    def test_store_id_is_set_when_product_registered_in_store
      event_store.publish(product_registered)
      event_store.publish(product_registered_in_store)

      assert_equal(store_id, Product.find(product_id).store_id)
    end

    def test_store_id_is_nil_when_product_not_registered_in_store
      event_store.publish(product_registered)

      assert_nil(Product.find(product_id).store_id)
    end

    def test_store_id_is_updated_when_product_registered_in_different_store
      store_2_id = SecureRandom.uuid

      event_store.publish(product_registered)
      event_store.publish(product_registered_in_store)

      assert_equal(store_id, Product.find(product_id).store_id)

      event_store.publish(product_registered_in_different_store(store_2_id))

      assert_equal(store_2_id, Product.find(product_id).store_id)
    end

    private

    def event_store
      Rails.configuration.event_store
    end

    def product_id
      @product_id ||= SecureRandom.uuid
    end

    def store_id
      @store_id ||= SecureRandom.uuid
    end

    def product_registered
      ProductCatalog::ProductRegistered.new(data: { product_id: product_id })
    end

    def product_registered_in_store
      Stores::ProductRegistered.new(data: { product_id: product_id, store_id: store_id })
    end

    def product_registered_in_different_store(different_store_id)
      Stores::ProductRegistered.new(data: { product_id: product_id, store_id: different_store_id })
    end
  end
end
