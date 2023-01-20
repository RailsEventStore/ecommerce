module Inventory
  class InventoryEntry
    include AggregateRoot

    InventoryNotAvailable = Class.new(StandardError)
    StockLevelUndefined = Class.new(StandardError)

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
      apply AvailabilityChanged.new(
        data: {
          product_id: @product_id,
          available: availability
        }
      )
    end

    def dispatch(quantity)
      apply StockLevelChanged.new(
        data: {
          product_id: @product_id,
          quantity: -quantity,
          stock_level: @in_stock - quantity
        }
      )
      apply AvailabilityChanged.new(
        data: {
          product_id: @product_id,
          available: availability
        }
      )
    end

    def reserve(quantity)
      raise StockLevelUndefined unless stock_level_defined?
      check_availability!(quantity)
      apply StockReserved.new(
        data: {
          product_id: @product_id,
          quantity: quantity
        }
      )
      apply AvailabilityChanged.new(
        data: {
          product_id: @product_id,
          available: availability
        }
      )
    end

    def release(quantity)
      apply StockReleased.new(
        data: {
          product_id: @product_id,
          quantity: quantity
        }
      )
      apply AvailabilityChanged.new(
        data: {
          product_id: @product_id,
          available: availability
        }
      )
    end

    def check_availability!(desired_quantity)
      return unless stock_level_defined?
      raise InventoryNotAvailable if desired_quantity > availability
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
