module Shipping
  class PickingListItem
    attr_reader :product_id, :quantity

    def initialize(product_id)
      @product_id = product_id
      @quantity = 0
    end

    def increase
      @quantity += 1
    end

    def decrease
      @quantity -= 1
    end
  end
end