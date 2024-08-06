module Ordering
  class Order
    include AggregateRoot

    InvalidState = Class.new(StandardError)
    AlreadySubmitted = Class.new(InvalidState)
    NotPlaced = Class.new(InvalidState)
    OrderHasExpired = Class.new(InvalidState)

    def initialize(id)
      @id = id
      @state = State.new(:draft)
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

    on OrderPlaced do |event|
      @state = @state.transition_to(:accepted)
    end

    on OrderExpired do |event|
      @state = @state.transition_to(:expired)
    end

    on ItemAddedToBasket do |event|
      @basket.increase_quantity(event.data[:product_id])
    end

    on ItemRemovedFromBasket do |event|
      @basket.decrease_quantity(event.data[:product_id])
    end

    on OrderSubmitted do |event|
      @order_number = event.data[:order_number]
      @state = @state.transition_to(:submitted)
    end

    on OrderRejected do |event|
      @state = State.new
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
  end

  class State
    ALLOWED_STATES = %i(draft submitted expired accepted)
    ALLOWED_TRANSITIONS = {
      draft: %i(submitted expired),
      submitted: %i(accepted rejected),
      expired: %i(draft)
    }


    def initialize(state = :draft)
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

    def transition_to(state)
      raise InvalidState unless ALLOWED_STATES.include?(state)
      raise InvalidState unless ALLOWED_TRANSITIONS[@state].include?(state)
      State.new(state)
    end
  end
end
