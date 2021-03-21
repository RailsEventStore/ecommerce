module Ecommerce
  class Cart
    include AggregateRoot

    def initialize(id)
      @id = id
    end

    def add_item(product_id)
    end
  end
end