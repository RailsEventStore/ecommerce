require_relative "test_helper"

module Inventory
  class CheckAvailabilityTest < Test
    def test_inventory_available_error_is_raised
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      publish_item_added_event(order_id, product_id, 0)
      arrange(
        supply(product_id, 2),
      )
      publish_item_added_event(order_id, product_id, 1)
      assert_raises(InventoryEntry::InventoryNotAvailable) do
        publish_item_added_event(order_id, product_id, 2)
      end
    end

    private

    def publish_item_added_event order_id, product_id, quantity_before
      event_store.publish(
        Ordering::ItemAddedToBasket.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity_before: quantity_before
          }
        )
      )
    end
  end
end