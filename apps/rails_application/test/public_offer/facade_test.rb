require "test_helper"

module PublicOffer
  class FacadeTest < InMemoryTestCase
    cover "PublicOffer.find_product"
    cover "PublicOffer.products_in_store"

    def configure(event_store, _command_bus)
      PublicOffer::Configuration.new(event_store).call
    end

    def test_find_product_returns_registered_product
      product_id = SecureRandom.uuid
      other_product_id = SecureRandom.uuid
      register_product(product_id, "Async Remote", 45)
      register_product(other_product_id, "Rails meets React", 50)

      assert_equal("Async Remote", PublicOffer.find_product(product_id).name)
      assert_equal(45, PublicOffer.find_product(product_id).price)
    end

    def test_products_in_store_returns_only_products_from_given_store
      store_1_id = SecureRandom.uuid
      store_2_id = SecureRandom.uuid
      product_1_id = SecureRandom.uuid
      product_2_id = SecureRandom.uuid
      product_3_id = SecureRandom.uuid

      register_product_in_store(product_1_id, "In store 1", store_1_id)
      register_product_in_store(product_2_id, "Also in store 1", store_1_id)
      register_product_in_store(product_3_id, "In store 2", store_2_id)

      result = PublicOffer.products_in_store(store_1_id)

      assert_equal(2, result.count)
      assert_equal([product_1_id, product_2_id].sort, result.pluck(:id).sort)
    end

    def test_products_in_store_returns_empty_when_no_products_in_store
      assert_equal(0, PublicOffer.products_in_store(SecureRandom.uuid).count)
    end

    private

    def register_product(product_id, name, price)
      event_store.publish(ProductCatalog::ProductRegistered.new(data: { product_id: product_id }))
      event_store.publish(ProductCatalog::ProductNamed.new(data: { product_id: product_id, name: name }))
      event_store.publish(Pricing::PriceSet.new(data: { product_id: product_id, price: price }))
    end

    def register_product_in_store(product_id, name, store_id)
      register_product(product_id, name, 10)
      event_store.publish(Stores::ProductRegistered.new(data: { product_id: product_id, store_id: store_id }))
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
