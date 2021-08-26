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
      raise AlreadySubmitted if submitted?
      apply ReservationAdjusted.new(data: {order_id: @order_id, product_id: product_id, quantity: quantity})
    end

    def submit(reserved_items)
      raise AlreadySubmitted if submitted?
      apply ReservationSubmitted.new(data: {order_id: @order_id, reservation_items: reserved_items.map(&:to_h) })
    end

    def complete
      raise NotSubmitted unless submitted?
      raise AlreadyCompleted if @state.equal?(:completed)
      raise AlreadyCanceled if @state.equal?(:canceled)
      apply ReservationCompleted.new(data: { order_id: @order_id, reservation_items: reservation_items.map(&:to_h) })
    end

    def cancel
      raise AlreadyCanceled if @state.equal?(:canceled)
      raise AlreadyCompleted if @state.equal?(:completed)
      apply ReservationCanceled.new(data: { order_id: @order_id, reservation_items: reservation_items.map(&:to_h) })
    end

    def submitted?
      !@state.nil?
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