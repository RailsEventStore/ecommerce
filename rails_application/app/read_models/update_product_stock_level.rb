# frozen_string_literal: true

class UpdateProductStockLevel
  def call(event)
    product = Product.find(event.data[:id])

    checkpoint = product.checkpoint

    product_stream = event_store.read.stream("Inventory::Product$#{product.id}")
    product_stream = product_stream.from(checkpoint) if checkpoint

    product_stream.each do |event|
      case event
      when Inventory::StockLevelIncreased
        product.increment!(:stock_level, event.data[:quantity])
      when Inventory::StockLevelDecreased
        product.decrement!(:stock_level, event.data[:quantity])
      end
      product.checkpoint = event.event_id
    end

    product.save!
  end

  private

  def event_store
    Rails.configuration.event_store
  end
end
