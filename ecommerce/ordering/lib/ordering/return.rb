module Ordering
  class Return
    include AggregateRoot

    ExceedsOrderQuantityError = Class.new(StandardError)
    ReturnHaveNotBeenRequestedForThisProductError = Class.new(StandardError)

    def initialize(id)
      @id = id
      @return_items = ItemsList.new
    end

    def create_draft(order_id, returnable_products)
      apply DraftReturnCreated.new(data: { return_id: @id, order_id: order_id, returnable_products: returnable_products })
    end

    def add_item(product_id)
      raise ExceedsOrderQuantityError unless enough_items?(product_id)
      apply ItemAddedToReturn.new(data: { return_id: @id, order_id: @order_id, product_id: product_id })
    end

    def remove_item(product_id)
      raise ReturnHaveNotBeenRequestedForThisProductError unless @return_items.quantity(product_id).positive?
      apply ItemRemovedFromReturn.new(data: { return_id: @id, order_id: @order_id, product_id: product_id })
    end

    on DraftReturnCreated do |event|
      @order_id = event.data[:order_id]
      @returnable_products = event.data[:returnable_products]
    end

    on ItemAddedToReturn do |event|
      @return_items.increase_quantity(event.data[:product_id])
    end

    on ItemRemovedFromReturn do |event|
      @return_items.decrease_quantity(event.data[:product_id])
    end

    private

    def enough_items?(product_id)
      @return_items.quantity(product_id) < returnable_quantity(product_id)
    end

    def returnable_quantity(product_id)
      product = @returnable_products.find { |product| product.fetch(:product_id) == product_id }
      product.fetch(:quantity)
    end
  end

  class ItemsList
    attr_reader :return_items

    def initialize
      @return_items = Hash.new(0)
    end

    def increase_quantity(product_id)
      return_items[product_id] = quantity(product_id) + 1
    end

    def decrease_quantity(product_id)
      return_items[product_id] -= 1
      return_items.delete(product_id) if quantity(product_id).equal?(0)
    end

    def quantity(product_id)
      return_items[product_id]
    end
  end

  Refund = Return
  RefundableProducts = ReturnableProducts if defined?(ReturnableProducts)
end
