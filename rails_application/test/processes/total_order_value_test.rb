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
          total_value: 100,
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
          total_value: 200,
          order_id: order_id
        }
      )) do
      process.call(event_2)
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
