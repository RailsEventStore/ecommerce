require "test_helper"

module Products
  class FacadeTest < InMemoryTestCase
    cover "Products*"

    def configure(event_store, _command_bus)
      Products::Configuration.new(event_store).call
    end

    def test_products_for_store_returns_only_products_from_given_store
      store_id_1 = SecureRandom.uuid
      store_id_2 = SecureRandom.uuid
      product_id_1 = SecureRandom.uuid
      product_id_2 = SecureRandom.uuid
      product_id_3 = SecureRandom.uuid

      register_product(product_id_1, store_id_1)
      register_product(product_id_2, store_id_1)
      register_product(product_id_3, store_id_2)

      result = Products.products_for_store(store_id_1)

      assert_equal(2, result.count)
      assert_equal([product_id_1, product_id_2].sort, result.pluck(:id).sort)
    end

    def test_products_for_store_returns_empty_when_no_products_in_store
      store_id = SecureRandom.uuid

      result = Products.products_for_store(store_id)

      assert_equal(0, result.count)
    end

    def test_find_product_returns_product_by_id
      product_id = SecureRandom.uuid
      store_id = SecureRandom.uuid

      register_product(product_id, store_id)

      result = Products.find_product(product_id)

      assert_equal(product_id, result.id)
    end

    def test_find_product_raises_when_not_found
      product_id = SecureRandom.uuid

      assert_raises(ActiveRecord::RecordNotFound) do
        Products.find_product(product_id)
      end
    end

    def test_product_names_for_ids_returns_names_for_given_ids
      store_id = SecureRandom.uuid
      product_id_1 = SecureRandom.uuid
      product_id_2 = SecureRandom.uuid
      product_id_3 = SecureRandom.uuid

      register_product(product_id_1, store_id)
      name_product(product_id_1, "Product 1")

      register_product(product_id_2, store_id)
      name_product(product_id_2, "Product 2")

      register_product(product_id_3, store_id)
      name_product(product_id_3, "Product 3")

      result = Products.product_names_for_ids([product_id_1, product_id_3])

      assert_equal(2, result.size)
      assert_equal(["Product 1", "Product 3"].sort, result.sort)
    end

    def test_product_names_for_ids_returns_empty_when_no_products_found
      result = Products.product_names_for_ids([SecureRandom.uuid])

      assert_equal(0, result.size)
    end

    def test_find_by_returns_product_by_attributes
      product_id = SecureRandom.uuid
      store_id = SecureRandom.uuid

      register_product(product_id, store_id)

      result = Products.find_by(id: product_id)

      assert_equal(product_id, result.id)
    end

    def test_find_by_returns_nil_when_not_found
      result = Products.find_by(id: SecureRandom.uuid)

      assert_nil(result)
    end

    private

    def register_product(product_id, store_id)
      event_store.publish(
        ProductCatalog::ProductRegistered.new(
          data: { product_id: product_id }
        )
      )
      event_store.publish(
        Stores::ProductRegistered.new(
          data: { product_id: product_id, store_id: store_id }
        )
      )
    end

    def name_product(product_id, name)
      event_store.publish(
        ProductCatalog::ProductNamed.new(
          data: { product_id: product_id, name: name }
        )
      )
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
