require_relative "test_helper"

module Inventory
  class DispatchTest < Test
    def test_nothing_changes_when_stock_level_is_undefined
      product_id = SecureRandom.uuid
      assert_events(inventory_entry_stream(product_id)) do
        act(dispatch(product_id, 1))
      end
    end

    def test_stock_level_changes_with_dispatch_command
      product_id = SecureRandom.uuid
      arrange(supply(product_id, 1))
      assert_events(
        inventory_entry_stream(product_id),
        StockLevelChanged.new(
          data: {
            product_id: product_id,
            quantity: -1,
            stock_level: 0
          }
        ),
        AvailabilityChanged.new(data: { product_id: product_id, available: 0 })
      ) do
        act(dispatch(product_id, 1))
      end
    end
  end
end
