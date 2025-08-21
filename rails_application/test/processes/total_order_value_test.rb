require "test_helper"

module Processes
  class TotalOrderValueTest < ProcessTest
    cover "Processes::TotalOrderValue"

    def test_total_order_value_calculation_for_1_item
      process = TotalOrderValue.new(event_store, command_bus)
      event = price_item_added

      event_store.append(event)

      assert_events_contain(
        "Processes::TotalOrderValue$#{event.data[:order_id]}",
        Processes::TotalOrderValueUpdated.new(
          data: {
            total_amount: 100,
            discounted_amount: 100,
            order_id: order_id
          }
        )) do
          process.call(event)
        end
    end

    def test_total_order_value_calculation_for_2_items_of_the_same_product
      process = TotalOrderValue.new(event_store, command_bus)
      product_id = SecureRandom.uuid
      event_1 = price_item_added(product_id)
      event_2 = price_item_added(product_id)

      event_store.append(event_1)
      event_store.append(event_2)

      process.call(event_1)

      assert_events_contain(
        "Processes::TotalOrderValue$#{event_2.data[:order_id]}",
        Processes::TotalOrderValueUpdated.new(
          data: {
            total_amount: 200,
            discounted_amount: 200,
            order_id: order_id
          }
        )) do
        process.call(event_2)
      end
    end

    def test_total_order_value_calculation_for_2_items_of_different_products
      process = TotalOrderValue.new(event_store, command_bus)
      product_id_1 = SecureRandom.uuid
      product_id_2 = SecureRandom.uuid
      event_1 = price_item_added(product_id_1)
      event_2 = price_item_added(product_id_2)

      event_store.append(event_1)
      event_store.append(event_2)

      process.call(event_1)

      assert_events_contain(
        "Processes::TotalOrderValue$#{event_2.data[:order_id]}",
        Processes::TotalOrderValueUpdated.new(
          data: {
            total_amount: 200,
            discounted_amount: 200,
            order_id: order_id
          }
        )) do
        process.call(event_2)
      end
    end

    def test_total_order_value_calculation_for_2_items_of_different_products_and_1_item_removed
      process = TotalOrderValue.new(event_store, command_bus)
      product_id_1 = SecureRandom.uuid
      product_id_2 = SecureRandom.uuid
      event_1 = price_item_added(product_id_1)
      event_2 = price_item_added(product_id_2)
      event_3 = Pricing::PriceItemRemoved.new(data: {
        order_id: order_id,
        product_id: product_id_1,
        base_price: 100,
        price: 100,
        base_total_value: 100,
        total_value: 100
      })
      event_store.append(event_1)
      event_store.append(event_2)
      event_store.append(event_3)
      process.call(event_1)
      process.call(event_2)
      assert_events_contain(
        "Processes::TotalOrderValue$#{event_3.data[:order_id]}",
        Processes::TotalOrderValueUpdated.new(
          data: {
            total_amount: 100,
            discounted_amount: 100,
            order_id: order_id
          }
        )) do
        process.call(event_3)
      end
    end

    def test_with_discount
      process = TotalOrderValue.new(event_store, command_bus)
      product_id = SecureRandom.uuid
      event_1 = price_item_added(product_id)
      event_2 = Pricing::PercentageDiscountSet.new(data: {
        order_id: order_id,
        type: "test_discount",
        amount: 10
      })
      event_store.append(event_1)
      event_store.append(event_2)
      process.call(event_1)
      assert_events_contain(
        "Processes::TotalOrderValue$#{event_2.data[:order_id]}",
        Processes::TotalOrderValueUpdated.new(
          data: {
            total_amount: 100,
            discounted_amount: 90,
            order_id: order_id
          }
        )) do
        process.call(event_2)
      end
    end

    def test_changed_discount
      process = TotalOrderValue.new(event_store, command_bus)
      product_id = SecureRandom.uuid
      event_1 = price_item_added(product_id)
      event_2 = Pricing::PercentageDiscountSet.new(data: {
        order_id: order_id,
        type: "test_discount",
        amount: 10
      })
      event_3 = Pricing::PercentageDiscountChanged.new(data: {
        order_id: order_id,
        type: "test_discount",
        amount: 20
      })
      event_store.append(event_1)
      event_store.append(event_2)
      event_store.append(event_3)
      process.call(event_1)
      process.call(event_2)
      assert_events_contain(
        "Processes::TotalOrderValue$#{event_3.data[:order_id]}",
        Processes::TotalOrderValueUpdated.new(
          data: {
            total_amount: 100,
            discounted_amount: 80,
            order_id: order_id
          }
        )) do
        process.call(event_3)
      end
    end

    def test_removed_discount
      process = TotalOrderValue.new(event_store, command_bus)
      product_id = SecureRandom.uuid
      event_1 = price_item_added(product_id)
      event_2 = Pricing::PercentageDiscountSet.new(data: {
        order_id: order_id,
        type: "test_discount",
        amount: 10
      })
      event_3 = Pricing::PercentageDiscountRemoved.new(data: {
        order_id: order_id,
        type: "test_discount"
      })
      event_store.append(event_1)
      event_store.append(event_2)
      event_store.append(event_3)
      process.call(event_1)
      process.call(event_2)
      assert_events_contain(
        "Processes::TotalOrderValue$#{event_3.data[:order_id]}",
        Processes::TotalOrderValueUpdated.new(
          data: {
            total_amount: 100,
            discounted_amount: 100,
            order_id: order_id
          }
        )) do
        process.call(event_3)
      end
    end

    private

    def price_item_added(product_id = SecureRandom.uuid)
      Pricing::PriceItemAdded.new(data: {
        order_id: order_id,
        price: 100,
        product_id: product_id,
        base_price: 100,
        base_total_value: 100,
        total_value: 100
      })
    end
  end
end
