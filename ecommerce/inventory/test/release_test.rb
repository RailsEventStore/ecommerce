require_relative "test_helper"

module Inventory
  class ReleaseTest < Test
    def test_stock_gets_released_when_reserved
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      arrange(Reserve.new(order_id: order_id, product_id: product_id, quantity: 1))
      assert_events(
        inventory_entry_stream(product_id),
        StockReleased.new(data: { order_id: order_id, product_id: product_id, quantity: 1 })
      ) do
        act(Release.new(order_id: order_id, product_id: product_id, quantity: 1))
      end
    end

    def test_stock_does_not_get_released_when_not_reserved
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      assert_raises(
        InventoryEntry::InventoryNotEvenReserved
      ) do
        act(Release.new(order_id: order_id, product_id: product_id, quantity: 1))
      end
    end
  end
end
