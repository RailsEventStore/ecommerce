require_relative "test_helper"

module Inventory
  class ReserveTest < Test
    def test_stock_gets_reserved_when_available
      product_id = SecureRandom.uuid
      arrange(supply(product_id, 1))

      assert_events(
        inventory_entry_stream(product_id),
        StockReserved.new(data: { product_id: product_id, quantity: 1 }),
        AvailabilityChanged.new(data: { product_id: product_id, available: 0 })
      ) do
        act(reserve(product_id, 1))
      end
    end

    def test_stock_gets_reserved_when_stock_level_undefined
      product_id = SecureRandom.uuid

      assert_events(
        inventory_entry_stream(product_id),
        StockReserved.new(data: { product_id: product_id, quantity: 1 })
      ) do
        act(reserve(product_id, 1))
      end
    end

    def test_raises_when_stock_unavailable
      product_id = SecureRandom.uuid
      arrange(supply(product_id, 1))

      assert_raises(InventoryEntry::InventoryNotAvailable) do
        act(reserve(product_id, 2))
      end
    end
  end
end
