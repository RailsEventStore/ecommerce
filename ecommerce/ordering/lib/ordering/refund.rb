module Ordering
  class Refund
    include AggregateRoot

    ProductNotFoundError = Class.new(StandardError)

    def initialize(id)
      @id = id
      @refund_items = ItemsList.new
    end

    def create_draft(order_id)
      apply DraftRefundCreated.new(data: { refund_id: @id, order_id: order_id })
    end

    def add_item(product_id)
      apply ItemAddedToRefund.new(data: { refund_id: @id, order_id: @order_id, product_id: product_id })
    end

    def remove_item(product_id)
      raise ProductNotFoundError unless @refund_items.quantity(product_id).positive?
      apply ItemRemovedFromRefund.new(data: { refund_id: @id, order_id: @order_id, product_id: product_id })
    end

    on DraftRefundCreated do |event|
      @order_id = event.data[:order_id]
    end

    on ItemAddedToRefund do |event|
      @refund_items.increase_quantity(event.data[:product_id])
    end

    on ItemRemovedFromRefund do |event|
      @refund_items.decrease_quantity(event.data[:product_id])
    end
  end

  class ItemsList
    attr_reader :refund_items

    def initialize
      @refund_items = Hash.new(0)
    end

    def increase_quantity(product_id)
      refund_items[product_id] = quantity(product_id) + 1
    end

    def decrease_quantity(product_id)
      refund_items[product_id] -= 1
      refund_items.delete(product_id) if refund_items.fetch(product_id).equal?(0)
    end

    def quantity(product_id)
      refund_items[product_id]
    end
  end
end
