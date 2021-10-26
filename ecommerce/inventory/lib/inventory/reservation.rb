module Inventory
  class Reservation
    include AggregateRoot

    AlreadySubmitted = Class.new(StandardError)
    AlreadyCompleted = Class.new(StandardError)
    AlreadyCanceled = Class.new(StandardError)
    NotSubmitted = Class.new(StandardError)

    ReservationItem = Struct.new(:product_id, :quantity, keyword_init: true)
    attr_accessor :reservation_items

    def initialize(order_id)
      @order_id = order_id
      @reservation_items = []
    end

    def submit(reserved_items)
      raise AlreadySubmitted if submitted?
      apply ReservationSubmitted.new(
              data: {
                order_id: @order_id,
                reservation_items: reserved_items
              }
            )
    end

    def complete
      raise NotSubmitted unless submitted?
      raise AlreadyCompleted if @state.equal?(:completed)
      raise AlreadyCanceled if @state.equal?(:canceled)
      apply ReservationCompleted.new(
              data: {
                order_id: @order_id,
                reservation_items: reservation_items.map(&:to_h)
              }
            )
    end

    def cancel
      raise AlreadyCanceled if @state.equal?(:canceled)
      raise AlreadyCompleted if @state.equal?(:completed)
      apply ReservationCanceled.new(
              data: {
                order_id: @order_id,
                reservation_items: reservation_items.map(&:to_h)
              }
            )
    end

    def submitted?
      !@state.nil?
    end

    private

    on ReservationSubmitted do |event|
      @reservation_items =
        event
          .data
          .fetch(:reservation_items)
          .map { |product_id, quantity| ReservationItem.new(product_id: product_id, quantity: quantity) }
      @state = :submitted
    end

    on ReservationCompleted do |event|
      @state = :completed
    end

    on ReservationCanceled do |event|
      @state = :canceled
    end
  end
end
