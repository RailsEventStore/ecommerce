require "test_helper"

module Processes
  class TotalOrderValueTest < ProcessTest
    cover "Processes::TotalOrderValue"

    def test_total_order_value_calculation
      process = TotalOrderValue.new(event_store)

      assert_events_contain(
        "Processes::TotalOrderValue$#{price_item_added.data[:order_id]}",
        Processes::TotalOrderValueUpdated.new(
          data: {
            total_value: 100,
            order_id: order_id
          }
        )) do
          process.call(price_item_added)
        end



    end

    private

    def price_item_added
      Pricing::PriceItemAdded.new(data: {
        order_id: order_id,
        item_id: SecureRandom.uuid,
        price: 100,
        product_id: SecureRandom.uuid,
        base_price: 100,
        base_total_value: 100,
        total_value: 100
      })
    end
  end
end
