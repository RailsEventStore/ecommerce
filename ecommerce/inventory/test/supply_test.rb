require_relative "test_helper"

module Inventory
  class SupplyTest < Test
    def test_stock_level_changes_with_supply_command
      product_id = SecureRandom.uuid
      assert_events(inventory_entry_stream(product_id),
                    StockLevelChanged.new(data: { product_id: product_id, quantity: 1, stock_level: 1 })) do
        act(supply(product_id, 1))
      end
      assert_events(inventory_entry_stream(product_id),
                    StockLevelChanged.new(data: { product_id: product_id, quantity: 1, stock_level: 2 })) do
        act(supply(product_id, 1))
      end
    end
  end
end


