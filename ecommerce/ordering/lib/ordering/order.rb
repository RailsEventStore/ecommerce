module Ordering
  class Order
    include AggregateRoot

    AlreadySubmitted = Class.new(StandardError)
    AlreadyPaid = Class.new(StandardError)
    NotSubmitted = Class.new(StandardError)
    OrderHasExpired = Class.new(StandardError)
    MissingCustomer = Class.new(StandardError)

    def initialize(id)
      @id = id
      @state = :draft
      @basket = Basket.new
    end

    def submit(order_number, customer_id)
      raise AlreadySubmitted if @state.equal?(:submitted)
      raise OrderHasExpired if @state.equal?(:expired)
      apply OrderSubmitted.new(
        data: {
          order_id: @id,
          order_number: order_number,
          customer_id: customer_id,
          order_lines: @basket.order_lines
        }
      )
    end

    def confirm
      raise OrderHasExpired if @state.equal?(:expired)
      raise NotSubmitted unless @state.equal?(:submitted)
      apply OrderPaid.new(data: { order_id: @id })
    end

    def expire
      raise AlreadyPaid if @state.equal?(:paid)
      apply OrderExpired.new(data: { order_id: @id })
    end

    def add_item(product_id)
      raise AlreadySubmitted unless @state.equal?(:draft)
      apply ItemAddedToBasket.new(
        data: {
          order_id: @id,
          product_id: product_id,
          quantity_before: @basket.quantity(product_id)
        }
      )
    end

    def remove_item(product_id)
      raise AlreadySubmitted unless @state.equal?(:draft)
      apply ItemRemovedFromBasket.new(data: { order_id: @id, product_id: product_id })
    end

    def cancel
      raise OrderHasExpired if @state.equal?(:expired)
      raise NotSubmitted unless @state.equal?(:submitted)
      apply OrderCancelled.new(data: { order_id: @id })
    end

    on OrderSubmitted do |event|
      @customer_id = event.data[:customer_id]
      @number = event.data[:order_number]
      @state = :submitted
    end

    on OrderPaid do |event|
      @state = :paid
    end

    on OrderExpired do |event|
      @state = :expired
    end

    on OrderCancelled do |event|
      @state = :cancelled
    end

    on ItemAddedToBasket do |event|
      @basket.increase_quantity(event.data[:product_id])
    end

    on ItemRemovedFromBasket do |event|
      @basket.decrease_quantity(event.data[:product_id])
    end
  end

  class Basket
    def initialize
      @order_lines = Hash.new(0)
    end

    def increase_quantity(product_id)
      @order_lines[product_id] = quantity(product_id) + 1
    end

    def decrease_quantity(product_id)
      return unless quantity(product_id) > 0
      @order_lines[product_id] -= 1
    end

    def order_lines
      @order_lines.select { |_, quantity| quantity != 0 }
    end

    def quantity(product_id)
      @order_lines[product_id]
    end
  end
end
