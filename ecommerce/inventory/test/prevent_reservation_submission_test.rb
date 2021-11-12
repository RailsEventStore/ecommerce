require_relative "test_helper"

module Inventory
  class PreventReservationSubmissionTest < Test
    def test_inventory_error_prevents_reservation_submission
      order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid

      arrange(
        supply(product_id, 1)
      )
      act(submit_reservation(order_id, product_id => 1))
      assert_raises(InventoryEntry::InventoryNotAvailable) do
        act(submit_reservation(order_id, product_id => 1))
      end
    end
  end
end