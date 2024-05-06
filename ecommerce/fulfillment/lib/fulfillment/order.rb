# frozen_string_literal: true

module Fulfillment
  class Order
    include AggregateRoot

    InvalidState = Class.new(StandardError)

    def initialize(id)
      @id = id
    end

    def register
      raise InvalidState if @state
      apply OrderRegistered.new(data: { order_id: @id })
    end

    def confirm
      raise InvalidState unless @state.equal?(:new)
      apply OrderConfirmed.new(data: { order_id: @id })
    end

    def cancel
      raise InvalidState unless @state.equal?(:new)
      apply OrderCancelled.new(data: { order_id: @id })
    end

    on OrderRegistered do |event|
      @state = :new
    end

    on OrderConfirmed do |event|
      @state = :confirmed
    end

    on OrderCancelled do |event|
      @state = :cancelled
    end
  end
end
