require "test_helper"

module Orders
  class FacadeTest < InMemoryTestCase
    cover "Orders*"

    def test_find_order_line_returns_first_matching_line
      order_id_1 = SecureRandom.uuid
      order_id_2 = SecureRandom.uuid
      product_id_1 = SecureRandom.uuid
      product_id_2 = SecureRandom.uuid

      register_product(product_id_1, "Product A", 10)
      add_item_to_order(order_id_1, product_id_1, 10)
      add_item_to_order(order_id_2, product_id_1, 10)

      register_product(product_id_2, "Product B", 20)
      add_item_to_order(order_id_2, product_id_2, 20)
      add_item_to_order(order_id_1, product_id_2, 20)

      result = Orders.find_order_line(order_uid: order_id_1, product_id: product_id_2)

      assert_equal(order_id_1, result.order_uid)
      assert_equal(product_id_2, result.product_id)
      assert_equal("Product B", result.product_name)
      assert_equal(20, result.price)
    end

    def test_find_order_line_returns_nil_when_not_found
      order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid

      result = Orders.find_order_line(order_uid: order_id, product_id: product_id)

      assert_nil(result)
    end

    def test_order_lines_for_returns_all_lines_for_order
      order_id_1 = SecureRandom.uuid
      order_id_2 = SecureRandom.uuid
      product_id_1 = SecureRandom.uuid
      product_id_2 = SecureRandom.uuid
      product_id_3 = SecureRandom.uuid

      register_product(product_id_1, "Product 1", 10)
      add_item_to_order(order_id_1, product_id_1, 10)

      register_product(product_id_2, "Product 2", 20)
      add_item_to_order(order_id_1, product_id_2, 20)

      register_product(product_id_3, "Product 3", 30)
      add_item_to_order(order_id_2, product_id_3, 30)

      result = Orders.order_lines_for(order_id_1)

      assert_equal(2, result.count)
      assert_equal([product_id_1, product_id_2].sort, result.pluck(:product_id).sort)
    end

    def test_order_lines_for_returns_empty_when_no_lines
      order_id_without_lines = SecureRandom.uuid
      order_id_with_lines = SecureRandom.uuid
      product_id = SecureRandom.uuid

      register_product(product_id, "Product", 10)
      add_item_to_order(order_id_with_lines, product_id, 10)

      result = Orders.order_lines_for(order_id_without_lines)

      assert_equal(0, result.count)
    end

    def test_find_product_returns_product_by_uid
      product_id = SecureRandom.uuid

      register_product(product_id, "Test Product", 100)

      result = Orders.find_product(product_id)

      assert_equal(product_id, result.uid)
      assert_equal("Test Product", result.name)
      assert_equal(100, result.price)
    end

    def test_find_product_raises_when_not_found
      product_id = SecureRandom.uuid

      assert_raises(ActiveRecord::RecordNotFound) do
        Orders.find_product(product_id)
      end
    end

    private

    def register_product(product_id, name, price)
      event_store.publish(
        ProductCatalog::ProductRegistered.new(
          data: { product_id: product_id }
        )
      )
      event_store.publish(
        ProductCatalog::ProductNamed.new(
          data: { product_id: product_id, name: name }
        )
      )
      event_store.publish(
        Pricing::PriceSet.new(data: { product_id: product_id, price: price })
      )
    end

    def add_item_to_order(order_id, product_id, price)
      event_store.publish(
        Pricing::PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            base_price: price,
            price: price,
            base_total_value: price,
            total_value: price,
          }
        )
      )
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
