# frozen_string_literal: true

module Inventory
  class StockLevelWillBeFulfilledWithin2BusinessDays
    def initialize(stock_level_ordered_for_tomorrow)
      @stock_level_ordered_for_tomorrow = stock_level_ordered_for_tomorrow
    end

    def can_fulfill?(stock_level)
      stock_level + @stock_level_ordered_for_tomorrow >= 0
    end
  end
end