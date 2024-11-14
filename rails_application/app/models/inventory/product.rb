# frozen_string_literal: true

module Inventory
  class Product
    include AggregateRoot

    private attr_reader :id

    def initialize(id)
      @id = id
      @stock_level = 0
    end

    def supply(quantity)
      apply(StockLevelIncreased.new(data: { id:, quantity: }))
    end

    def withdraw(quantity, can_oversell: nil)
      enough_stock =
        if can_oversell
          can_oversell.can_fulfill?(@stock_level)
        else
          @stock_level > quantity
        end

      raise "Not enough stock" unless enough_stock
      apply(StockLevelDecreased.new(data: { id:, quantity: }))
    end

    on StockLevelIncreased do |event|
      @stock_level += event.data[:quantity]
    end

    on StockLevelDecreased do |event|
      @stock_level -= event.data[:quantity]
    end

    on StockLevelMigrated do |event|
      @stock_level = event.data[:quantity]
    end
  end
end
