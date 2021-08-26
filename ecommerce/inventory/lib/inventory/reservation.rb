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

    def adjust(product_id, quantity)
      raise AlreadySubmitted if @state
      apply ReservationAdjusted.new(data: {order_id: @order_id, product_id: product_id, quantity: quantity})
    end

    def submit(reservation_items)
      raise AlreadySubmitted if @state
      apply ReservationSubmitted.new(data: {order_id: @order_id, reservation_items: reservation_items.map(&:to_h) })
    end

    def complete
      raise NotSubmitted unless @state
      raise AlreadyCompleted if @state.equal?(:completed)
      raise AlreadyCanceled if @state.equal?(:canceled)
      apply ReservationCompleted.new(data: { order_id: @order_id, reservation_items: @reservation_items.map(&:to_h) })
    end

    def cancel
      raise NotSubmitted unless @state
      raise AlreadyCanceled if @state.equal?(:canceled)
      apply ReservationCanceled.new(data: { order_id: @order_id, reservation_items: @reservation_items.map(&:to_h) })
    end

    private

    on ReservationAdjusted do |event|
      product_id = event.data.fetch(:product_id)
      quantity = event.data.fetch(:quantity)
      item = @reservation_items.find { |item| item.product_id == product_id }
      @reservation_items << (item = ReservationItem.new(product_id: product_id, quantity: 0)) unless item
      item.quantity += quantity
    end

    on ReservationSubmitted do |event|
      @reservation_items = event.data.fetch(:reservation_items).map { |hash| ReservationItem.new(hash) }
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