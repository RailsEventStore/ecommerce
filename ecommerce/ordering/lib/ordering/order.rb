module Ordering
  class Order
    include AggregateRoot

    InvalidState = Class.new(StandardError)
    AlreadySubmitted = Class.new(InvalidState)
    NotPlaced = Class.new(InvalidState)
    OrderHasExpired = Class.new(InvalidState)

    def initialize(id)
      @id = id
      @state = State.draft
      @basket = Basket.new
    end

    def submit(order_number)
      raise OrderHasExpired if @state.expired?
      raise AlreadySubmitted unless @state.draft?
      apply OrderSubmitted.new(
        data: {
          order_id: @id,
          order_number: order_number,
          order_lines: @basket.order_lines
        }
      )
    end

    def accept
      raise InvalidState unless @state.submitted?
      apply OrderPlaced.new(
        data: {
          order_id: @id,
          order_number: @order_number,
          order_lines: @basket.order_lines
        }
      )
    end

    def reject
      raise InvalidState unless @state.submitted?
      apply OrderRejected.new(
        data: {
          order_id: @id
        }
      )
    end

    def expire
      raise AlreadySubmitted unless @state.draft?
      apply OrderExpired.new(data: { order_id: @id })
    end

    def add_item(product_id)
      raise AlreadySubmitted unless @state.draft?
      apply ItemAddedToBasket.new(
        data: {
          order_id: @id,
          product_id: product_id,
        }
      )
    end

    def remove_item(product_id)
      raise AlreadySubmitted unless @state.draft?
      apply ItemRemovedFromBasket.new(data: { order_id: @id, product_id: product_id })
    end

    on OrderPlaced do |_|
      @state = State.new(:accepted)
    end

    on OrderExpired do |_|
      @state = State.expired
    end

    on ItemAddedToBasket do |event|
      @basket.increase_quantity(event.data[:product_id])
    end

    on ItemRemovedFromBasket do |event|
      @basket.decrease_quantity(event.data[:product_id])
    end

    on OrderSubmitted do |event|
      @order_number = event.data[:order_number]
      @state = State.submitted
    end

    on OrderRejected do |_|
      @state = State.draft
    end

    class Basket
      def initialize
        @order_lines = Hash.new(0)
      end

      def increase_quantity(product_id)
        order_lines[product_id] = quantity(product_id) + 1
      end

      def decrease_quantity(product_id)
        order_lines[product_id] -= 1
        order_lines.delete(product_id) if order_lines.fetch(product_id).equal?(0)
      end

      def order_lines
        @order_lines
      end

      def quantity(product_id)
        order_lines[product_id]
      end
    end

    class State
      def self.draft
        new(:draft)
      end

      def self.submitted
        new(:submitted)
      end

      def self.expired
        new(:expired)
      end

      def initialize(state)
        @state = state
      end

      def draft?
        @state.equal?(:draft)
      end

      def submitted?
        @state.equal?(:submitted)
      end

      def expired?
        @state.equal?(:expired)
      end
    end
  end
end
