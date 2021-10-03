module Shipping
  class Shipment
    include AggregateRoot

    ItemNotFound = Class.new(StandardError)

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

    private

    on ItemAddedToShipmentPickingList do |event|
      @picking_list.increase_item_quantity(event.data.fetch(:product_id))
    end

    on ItemRemovedFromShipmentPickingList do |event|
      @picking_list.decrease_item_quantity(event.data.fetch(:product_id))
    end

    def has_item?(product_id)
      @picking_list.has_item?(product_id)
    end
  end
end
