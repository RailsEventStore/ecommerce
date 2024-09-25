# frozen_string_literal: true

class UpdateProductStockLevel
  def call(event)
    product = Product.find(event.data[:id])

    case event
    when Inventory::StockLevelIncreased
      product.increment!(:stock_level, event.data[:quantity])
    when Inventory::StockLevelDecreased
      product.decrement!(:stock_level, event.data[:quantity])
    end
  end
end
