# frozen_string_literal: true

module Inventory
  SupplyStockLevel = Struct.new(:product_id, :quantity) do
    def initialize(product_id, quantity)
      super(product_id.to_i, quantity.to_i)
    end
  end
end
