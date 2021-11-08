require_relative "test_helper"

module Inventory
  class PreventOrderSubmissionTest < Test
    def test_inventory_error_prevents_order_submission
      order_id = SecureRandom.uuid
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid

      arrange(
        Inventory::Supply.new(product_id: product_id, quantity: 1)
      )

      assert_raises(InventoryEntry::InventoryNotAvailable) do
        event_store.publish(
          Ordering::OrderSubmitted.new(
            data: {
              order_id: order_id,
              order_number: "2021/11/1",
              customer_id: customer_id,
              order_lines: { product_id => 2 }
            }
          )
        )
      end
    end
  end
end