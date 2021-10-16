module Shipping
  class Shipment
    include AggregateRoot
    attr_reader :state, :shipping_address

    ItemNotFound = Class.new(StandardError)
    ShippingAddressMissing = Class.new(StandardError)
    NotSubmitted = Class.new(StandardError)
    AlreadySubmitted = Class.new(StandardError)
    AlreadyAuthorized = Class.new(StandardError)

    def initialize(order_id)
      @order_id = order_id
      @picking_list = PickingList.new
      @state = :draft
    end

    def add_item(product_id)
      apply ItemAddedToShipmentPickingList.new(
        data: {
          order_id: @order_id,
          product_id: product_id
        }
      )
    end

    def remove_item(product_id)
      raise ItemNotFound unless has_item?(product_id)

      apply ItemRemovedFromShipmentPickingList.new(
        data: {
          order_id: @order_id,
          product_id: product_id
        }
      )
    end

    def add_address(line_1, line_2, line_3, line_4)
      apply ShippingAddressAddedToShipment.new(
        data: {
          order_id: @order_id,
          line_1: line_1,
          line_2: line_2,
          line_3: line_3,
          line_4: line_4
        }
      )
    end

    def submit
      raise AlreadySubmitted if state.equal?(:submitted)
      raise ShippingAddressMissing unless state.equal?(:address_set)

      apply ShipmentSubmitted.new(
        data: {
          order_id: @order_id
        }
      )
    end

    def authorize
      raise AlreadyAuthorized if state.equal?(:authorized)
      raise NotSubmitted unless state.equal?(:submitted)

      apply ShipmentAuthorized.new(
        data: {
          order_id: @order_id
        }
      )
    end

    private

    on ItemAddedToShipmentPickingList do |event|
      @picking_list.increase_item_quantity(event.data.fetch(:product_id))
    end

    on ItemRemovedFromShipmentPickingList do |event|
      @picking_list.decrease_item_quantity(event.data.fetch(:product_id))
    end

    on ShippingAddressAddedToShipment do |event|
      @shipping_address = PostalAddress.new(
        line_1: event.data.fetch(:line_1),
        line_2: event.data.fetch(:line_2),
        line_3: event.data.fetch(:line_3),
        line_4: event.data.fetch(:line_4)
      )
      @state = :address_set
    end

    on ShipmentSubmitted do |event|
      @state = :submitted
    end

    on ShipmentAuthorized do |event|
      @state = :authorized
    end

    def has_item?(product_id)
      @picking_list.has_item?(product_id)
    end
  end
end
