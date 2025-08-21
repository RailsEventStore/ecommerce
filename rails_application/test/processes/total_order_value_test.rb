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

    def test_remove_specific_discount_when_multiple_discounts_exist
      process = TotalOrderValue.new(event_store, command_bus)
      product_id = SecureRandom.uuid
      
      event_1 = price_item_added(product_id)
      event_2 = Pricing::PercentageDiscountSet.new(data: {
        order_id: order_id,
        type: "general_discount",
        amount: 10
      })
      event_3 = Pricing::PercentageDiscountSet.new(data: {
        order_id: order_id,
        type: "time_promotion_discount",
        amount: 20
      })
      event_4 = Pricing::PercentageDiscountRemoved.new(data: {
        order_id: order_id,
        type: "general_discount"
      })
      
      event_store.append(event_1)
      event_store.append(event_2)
      event_store.append(event_3)
      event_store.append(event_4)
      
      process.call(event_1)
      process.call(event_2)
      process.call(event_3)
      
      assert_events_contain(
        "Processes::TotalOrderValue$#{event_4.data[:order_id]}",
        Processes::TotalOrderValueUpdated.new(
          data: {
            total_amount: 100,
            discounted_amount: 80,
            order_id: order_id
          }
        )) do
        process.call(event_4)
      end
    end

    def test_discount_capped_at_100_percent_via_multiple_discounts
      process = TotalOrderValue.new(event_store, command_bus)
      product_id = SecureRandom.uuid
      
      event_1 = price_item_added(product_id)
      event_2 = Pricing::PercentageDiscountSet.new(data: {
        order_id: order_id,
        type: "first_discount",
        amount: 60
      })
      
      event_3 = Pricing::PercentageDiscountSet.new(data: {
        order_id: order_id,
        type: "second_discount",
        amount: 30
      })
      
      event_4 = Pricing::PercentageDiscountSet.new(data: {
        order_id: order_id,
        type: "third_discount",
        amount: 25
      })
      
      event_store.append(event_1)
      event_store.append(event_2)
      event_store.append(event_3)
      event_store.append(event_4)
      
      process.call(event_1)
      process.call(event_2)
      process.call(event_3)
      
      assert_events_contain(
        "Processes::TotalOrderValue$#{event_4.data[:order_id]}",
        Processes::TotalOrderValueUpdated.new(
          data: {
            total_amount: 100,
            discounted_amount: 0,
            order_id: order_id
          }
        )) do
        process.call(event_4)
      end
    end

    def test_multiple_discounts_exceeding_100_percent
      process = TotalOrderValue.new(event_store, command_bus)
      product_id = SecureRandom.uuid
      
      event_1 = price_item_added(product_id)
      event_2 = Pricing::PercentageDiscountSet.new(data: {
        order_id: order_id,
        type: "first_discount",
        amount: 70
      })
      
      event_3 = Pricing::PercentageDiscountSet.new(data: {
        order_id: order_id,
        type: "second_discount",
        amount: 50
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
            discounted_amount: 0,
            order_id: order_id
          }
        )) do
        process.call(event_3)
      end
    end

    def test_discount_exactly_100_percent
      process = TotalOrderValue.new(event_store, command_bus)
      product_id = SecureRandom.uuid
      
      event_1 = price_item_added(product_id)
      event_2 = Pricing::PercentageDiscountSet.new(data: {
        order_id: order_id,
        type: "full_discount",
        amount: 100
      })
      
      event_store.append(event_1)
      event_store.append(event_2)
      
      process.call(event_1)
      
      assert_events_contain(
        "Processes::TotalOrderValue$#{event_2.data[:order_id]}",
        Processes::TotalOrderValueUpdated.new(
          data: {
            total_amount: 100,
            discounted_amount: 0,
            order_id: order_id
          }
        )) do
        process.call(event_2)
      end
    end

    def test_setting_same_discount_type_twice_replaces_first
      process = TotalOrderValue.new(event_store, command_bus)
      product_id = SecureRandom.uuid
      
      event_1 = price_item_added(product_id)
      event_2 = Pricing::PercentageDiscountSet.new(data: {
        order_id: order_id,
        type: "replaceable_discount",
        amount: 20
      })
      
      event_3 = Pricing::PercentageDiscountSet.new(data: {
        order_id: order_id,
        type: "replaceable_discount",
        amount: 30
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
            discounted_amount: 70,
            order_id: order_id
          }
        )) do
        process.call(event_3)
      end
    end

    def test_changing_discount_with_different_amount
      process = TotalOrderValue.new(event_store, command_bus)
      product_id = SecureRandom.uuid
      
      event_1 = price_item_added(product_id)
      event_2 = Pricing::PercentageDiscountSet.new(data: {
        order_id: order_id,
        type: "changeable_discount",
        amount: 25
      })
      event_3 = Pricing::PercentageDiscountChanged.new(data: {
        order_id: order_id,
        type: "changeable_discount",
        amount: 35
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
            discounted_amount: 65,
            order_id: order_id
          }
        )) do
        process.call(event_3)
      end
    end

    def test_changing_specific_discount_preserves_other_discounts
      process = TotalOrderValue.new(event_store, command_bus)
      product_id = SecureRandom.uuid
      
      event_1 = price_item_added(product_id)
      event_2 = Pricing::PercentageDiscountSet.new(data: {
        order_id: order_id,
        type: "general_discount",
        amount: 15
      })
      
      event_3 = Pricing::PercentageDiscountSet.new(data: {
        order_id: order_id,
        type: "time_promotion_discount",
        amount: 25
      })
      
      event_4 = Pricing::PercentageDiscountChanged.new(data: {
        order_id: order_id,
        type: "general_discount",
        amount: 10
      })
      
      event_store.append(event_1)
      event_store.append(event_2)
      event_store.append(event_3)
      event_store.append(event_4)
      
      process.call(event_1)
      process.call(event_2)
      process.call(event_3)
      
      assert_events_contain(
        "Processes::TotalOrderValue$#{event_4.data[:order_id]}",
        Processes::TotalOrderValueUpdated.new(
          data: {
            total_amount: 100,
            discounted_amount: 65,
            order_id: order_id
          }
        )) do
        process.call(event_4)
      end
    end

    def test_discount_hash_structure_integrity_after_change
      process = TotalOrderValue.new(event_store, command_bus)
      product_id = SecureRandom.uuid
      
      event_1 = price_item_added(product_id)
      event_2 = Pricing::PercentageDiscountSet.new(data: {
        order_id: order_id,
        type: "structural_test_discount",
        amount: 20
      })
      event_3 = Pricing::PercentageDiscountChanged.new(data: {
        order_id: order_id,
        type: "structural_test_discount",
        amount: 30
      })
      
      event_store.append(event_1)
      event_store.append(event_2)
      event_store.append(event_3)
      
      process.call(event_1)
      process.call(event_2)
      process.call(event_3)
      
      event_4 = Pricing::PercentageDiscountSet.new(data: {
        order_id: order_id,
        type: "another_discount",
        amount: 5
      })
      
      event_store.append(event_4)
      
      assert_events_contain(
        "Processes::TotalOrderValue$#{event_4.data[:order_id]}",
        Processes::TotalOrderValueUpdated.new(
          data: {
            total_amount: 100,
            discounted_amount: 65,
            order_id: order_id
          }
        )) do
        process.call(event_4)
      end
      event_5 = Pricing::PercentageDiscountRemoved.new(data: {
        order_id: order_id,
        type: "structural_test_discount"
      })
      
      event_store.append(event_5)
      assert_events_contain(
        "Processes::TotalOrderValue$#{event_5.data[:order_id]}",
        Processes::TotalOrderValueUpdated.new(
          data: {
            total_amount: 100,
            discounted_amount: 95,  # Only 5% discount remaining
            order_id: order_id
          }
        )) do
        process.call(event_5)
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
