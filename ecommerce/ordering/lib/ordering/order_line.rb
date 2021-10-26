module Ordering
  class OrderLine
    include Comparable
    attr_reader :product_id, :quantity

    def initialize(product_id)
      @product_id = product_id
      @quantity = 0
    end

    def increase_quantity
      @quantity += 1
    end

    def decrease_quantity
      @quantity -= 1
    end

    def empty?
      quantity.eql?(0)
    end

    def <=>(other)
      self.product_id <=> other.product_id
    end
  end
end