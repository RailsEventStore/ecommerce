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

      assert_equal(store_id, PublicOffer.find_product(product_id).store_id)
    end

    def test_store_id_is_nil_when_product_not_registered_in_store
      event_store.publish(product_registered)

      assert_nil(PublicOffer.find_product(product_id).store_id)
    end

    def test_store_id_is_updated_when_product_registered_in_different_store
      store_2_id = SecureRandom.uuid

      event_store.publish(product_registered)
      event_store.publish(product_registered_in_store)

      assert_equal(store_id, PublicOffer.find_product(product_id).store_id)

      event_store.publish(product_registered_in_different_store(store_2_id))

      assert_equal(store_2_id, PublicOffer.find_product(product_id).store_id)
    end

    def test_lowest_recent_price_lower_from_current_is_false_when_no_lowest_recorded
      refute(Product.new(price: 50, lowest_recent_price: nil).lowest_recent_price_lower_from_current?)
    end

    def test_lowest_recent_price_lower_from_current_is_false_when_equal_to_current
      refute(Product.new(price: 50, lowest_recent_price: 50).lowest_recent_price_lower_from_current?)
    end

    def test_lowest_recent_price_lower_from_current_is_false_when_higher_than_current
      refute(Product.new(price: 50, lowest_recent_price: 80).lowest_recent_price_lower_from_current?)
    end

    def test_lowest_recent_price_lower_from_current_is_true_when_lower_than_current
      assert(Product.new(price: 50, lowest_recent_price: 30).lowest_recent_price_lower_from_current?)
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
