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

      result = Orders.find_order(order_id_1).order_lines

      assert_equal(2, result.count)
      assert_equal([product_id_1, product_id_2].sort, result.pluck(:product_id).sort)
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

    def test_paginated_orders_returns_paginated_results
      store_id = SecureRandom.uuid
      order_ids = 15.times.map { SecureRandom.uuid }
      order_ids.each { |id| draft_order_in_store(id, store_id) }

      result = Orders.paginated_orders(1, store_id)

      assert_equal(10, result.size)
    end

    def test_paginated_orders_returns_orders_in_reverse_id_order
      store_id = SecureRandom.uuid
      order_id_1 = SecureRandom.uuid
      order_id_2 = SecureRandom.uuid
      order_id_3 = SecureRandom.uuid

      draft_order_in_store(order_id_1, store_id)
      draft_order_in_store(order_id_2, store_id)
      draft_order_in_store(order_id_3, store_id)

      result = Orders.paginated_orders(0, store_id)

      assert_equal(order_id_3, result.first.uid)
      assert_equal(order_id_1, result.last.uid)
    end

    def test_paginated_orders_returns_second_page
      store_id = SecureRandom.uuid
      order_ids = 15.times.map { SecureRandom.uuid }
      order_ids.each { |id| draft_order_in_store(id, store_id) }

      result = Orders.paginated_orders(2, store_id)

      assert_equal(5, result.size)
    end

    def test_paginated_orders_limits_to_10_per_page
      store_id = SecureRandom.uuid
      order_ids = 12.times.map { SecureRandom.uuid }
      order_ids.each { |id| draft_order_in_store(id, store_id) }

      result = Orders.paginated_orders(1, store_id)

      assert_equal(10, result.size)
    end

    def test_paginated_orders_filters_by_store_id
      store_id_1 = SecureRandom.uuid
      store_id_2 = SecureRandom.uuid
      order_id_1 = SecureRandom.uuid
      order_id_2 = SecureRandom.uuid
      order_id_3 = SecureRandom.uuid

      draft_order_in_store(order_id_1, store_id_1)
      draft_order_in_store(order_id_2, store_id_1)
      draft_order_in_store(order_id_3, store_id_2)

      result = Orders.paginated_orders(0, store_id_1)

      assert_equal(2, result.size)
      assert_equal([order_id_1, order_id_2].sort, result.pluck(:uid).sort)
    end

    def test_paginated_orders_returns_empty_when_no_orders_in_store
      store_id = SecureRandom.uuid

      result = Orders.paginated_orders(0, store_id)

      assert_equal(0, result.count)
    end

    def test_all_orders_returns_empty_when_no_orders
      result = Orders.all_orders

      assert_equal(0, result.count)
    end

    def test_all_orders_returns_all_orders_not_scoped
      order_id_1 = SecureRandom.uuid
      order_id_2 = SecureRandom.uuid

      draft_order(order_id_1)
      draft_order(order_id_2)
      submit_order(order_id_1)

      result = Orders.all_orders

      assert_equal(2, result.size)
      assert_includes(result.pluck(:uid), order_id_1)
      assert_includes(result.pluck(:uid), order_id_2)
    end

    def test_find_order_returns_order_by_uid
      order_id = SecureRandom.uuid

      draft_order(order_id)

      result = Orders.find_order(order_id)

      assert_equal(order_id, result.uid)
    end

    def test_find_order_returns_nil_when_not_found
      order_id = SecureRandom.uuid

      result = Orders.find_order(order_id)

      assert_nil(result)
    end

    def test_find_order_bang_returns_order_by_uid
      order_id = SecureRandom.uuid

      draft_order(order_id)

      result = Orders.find_order!(order_id)

      assert_equal(order_id, result.uid)
    end

    def test_find_order_bang_raises_when_not_found
      order_id = SecureRandom.uuid

      assert_raises(ActiveRecord::RecordNotFound) do
        Orders.find_order!(order_id)
      end
    end

    def test_find_order_in_store_returns_order_in_correct_store
      store_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      draft_order_in_store(order_id, store_id)

      result = Orders.find_order_in_store(order_id, store_id)

      assert_equal(order_id, result.uid)
      assert_equal(store_id, result.store_id)
    end

    def test_find_order_in_store_returns_nil_when_order_in_different_store
      store_id_1 = SecureRandom.uuid
      store_id_2 = SecureRandom.uuid
      order_id = SecureRandom.uuid

      draft_order_in_store(order_id, store_id_1)

      result = Orders.find_order_in_store(order_id, store_id_2)

      assert_nil(result)
    end

    def test_find_order_in_store_returns_nil_when_order_not_found
      store_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      result = Orders.find_order_in_store(order_id, store_id)

      assert_nil(result)
    end

    def test_find_or_create_order_returns_existing_order
      order_id = SecureRandom.uuid

      draft_order(order_id)

      result = Orders.find_or_create_order(order_id)

      assert_equal(order_id, result.uid)
      assert_equal(false, result.new_record?)
    end

    def test_find_or_create_order_creates_new_order_when_not_found
      order_id = SecureRandom.uuid

      result = Orders.find_or_create_order(order_id)

      assert_equal(order_id, result.uid)
      assert_equal(false, result.new_record?)
    end

    def test_draft_orders_returns_only_draft_orders
      draft_order_id_1 = SecureRandom.uuid
      draft_order_id_2 = SecureRandom.uuid
      submitted_order_id = SecureRandom.uuid

      draft_order(draft_order_id_1)
      draft_order(draft_order_id_2)
      draft_order(submitted_order_id)
      submit_order(submitted_order_id)

      result = Orders.draft_orders

      assert_equal(2, result.count)
      assert_equal([draft_order_id_1, draft_order_id_2].sort, result.pluck(:uid).sort)
    end

    def test_draft_orders_returns_empty_when_no_draft_orders
      order_id = SecureRandom.uuid

      draft_order(order_id)
      submit_order(order_id)

      result = Orders.draft_orders

      assert_equal(0, result.count)
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

    def draft_order(order_id)
      event_store.publish(
        Pricing::OfferDrafted.new(data: { order_id: order_id })
      )
    end

    def draft_order_in_store(order_id, store_id)
      draft_order(order_id)
      event_store.publish(
        Stores::OfferRegistered.new(data: { order_id: order_id, store_id: store_id })
      )
    end

    def submit_order(order_id)
      event_store.publish(
        Fulfillment::OrderRegistered.new(data: { order_id: order_id, order_number: "2024/01/123" })
      )
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
