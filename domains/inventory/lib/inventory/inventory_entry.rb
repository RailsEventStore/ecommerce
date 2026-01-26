module Inventory
  class InventoryEntry
    include AggregateRoot

    InventoryNotAvailable = Class.new(StandardError)
    InventoryNotEvenReserved = Class.new(StandardError)

    def initialize(product_id)
      @product_id = product_id
      @reserved = 0
    end

    def supply(quantity)
      apply StockLevelChanged.new(
        data: {
          product_id: @product_id,
          quantity: quantity,
          stock_level: (@in_stock || 0) + quantity
        }
      )
      apply_availability_changed
    end

    def dispatch(quantity)
      apply StockLevelChanged.new(
        data: {
          product_id: @product_id,
          quantity: -quantity,
          stock_level: @in_stock - quantity
        }
      ) if stock_level_defined?
      apply_availability_changed
    end

    def reserve(quantity)
      raise InventoryNotAvailable if stock_level_defined? && quantity > availability
      apply StockReserved.new(
        data: {
          product_id: @product_id,
          quantity: quantity
        }
      )
      apply_availability_changed
    end

    def release(quantity)
      raise InventoryNotEvenReserved if quantity > @reserved
      apply StockReleased.new(
        data: {
          product_id: @product_id,
          quantity: quantity
        }
      )
      apply_availability_changed
    end

    private

    def apply_availability_changed
      apply AvailabilityChanged.new(
        data: {
          product_id: @product_id,
          available: availability
        }
      ) if stock_level_defined?
    end

    on StockLevelChanged do |event|
      @in_stock = event.data.fetch(:stock_level)
    end

    on StockReserved do |event|
      @reserved += event.data.fetch(:quantity)
    end

    on StockReleased do |event|
      @reserved -= event.data.fetch(:quantity)
    end

    on AvailabilityChanged do |_|
    end

    def availability
      @in_stock - @reserved
    end

    def stock_level_defined?
      !@in_stock.nil?
    end
  end
end
