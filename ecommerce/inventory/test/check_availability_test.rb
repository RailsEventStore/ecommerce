require_relative "test_helper"

module Inventory
  class CheckAvailabilityTest < Test
    def test_inventory_not_available_error_is_raised
      product_id = SecureRandom.uuid
      act(CheckAvailability.new(product_id: product_id, desired_quantity: 1))
      act(Supply.new(product_id: product_id, quantity: 1))
      act(CheckAvailability.new(product_id: product_id, desired_quantity: 1))
      assert_raises(InventoryEntry::InventoryNotAvailable) do
        act(CheckAvailability.new(product_id: product_id, desired_quantity: 2))
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