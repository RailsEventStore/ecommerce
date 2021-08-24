module Inventory
  class InventoryEntry
    include AggregateRoot

    InventoryNotAvailable = Class.new(StandardError)
    StockLevelUndefined = Class.new(StandardError)
    NotEvenReserved = Class.new(StandardError)

    def initialize(product_id)
      @product_id = product_id
      @reserved = 0
    end

    def supply(quantity)
      apply StockLevelChanged.new(data: { product_id: @product_id, quantity: quantity, stock_level: (@in_stock || 0) + quantity })
    end

    def dispatch(quantity)
      raise StockLevelUndefined unless @in_stock
      apply StockLevelChanged.new(data: { product_id: @product_id, quantity: -quantity, stock_level: @in_stock - quantity })
    end

    def reserve(quantity)
      check_availability(quantity)
      apply StockReserved.new(data: { product_id: @product_id, quantity: quantity })
    end

    def release(quantity)
      raise NotEvenReserved unless @reserved
      # raise NotEvenReserved if @reserved < quantity
      apply StockReleased.new(data: { product_id: @product_id, quantity: quantity })
    end

    def check_availability(quantity)
      raise StockLevelUndefined unless @in_stock
      raise InventoryNotAvailable if quantity > availability
    end

    private

    on StockLevelChanged do |event|
      @in_stock = event.data.fetch(:stock_level)
    end

    on StockReserved do |event|
      @reserved += event.data.fetch(:quantity)
    end

    on StockReleased do |event|
      @reserved -= event.data.fetch(:quantity)
    end

    def availability
      @in_stock - @reserved
    end
  end
end