require_relative 'inventory_in_memory_test_case'

module Inventory
  class SupplyTest < InventoryInMemoryTestCase

    test 'stock level changes with supply command' do
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


