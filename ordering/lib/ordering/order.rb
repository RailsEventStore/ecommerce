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
    end

    def submit(order_number, customer_id)
      raise AlreadySubmitted if @state.equal?(:submitted)
      raise OrderHasExpired  if @state.equal?(:expired)
      apply OrderSubmitted.new(data: {order_id: @id, order_number: order_number, customer_id: customer_id})
    end

    def confirm(transaction_id)
      raise OrderHasExpired if @state.equal?(:expired)
      raise NotSubmitted unless @state.equal?(:submitted)
      apply OrderPaid.new(data: {order_id: @id, transaction_id: transaction_id})
    end

    def expire
      raise AlreadyPaid if @state.equal?(:paid)
      apply OrderExpired.new(data: {order_id: @id})
    end

    def add_item(product_id)
      raise AlreadySubmitted unless @state.equal?(:draft)
      apply ItemAddedToBasket.new(data: {order_id: @id, product_id: product_id})
    end

    def remove_item(product_id)
      raise AlreadySubmitted unless @state.equal?(:draft)
      apply ItemRemovedFromBasket.new(data: {order_id: @id, product_id: product_id})
    end

    def cancel
      raise OrderHasExpired if @state.equal?(:expired)
      raise NotSubmitted unless @state.equal?(:submitted)
      apply OrderCancelled.new(data: {order_id: @id})
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
    end

    on ItemRemovedFromBasket do |event|
    end
  end
end
