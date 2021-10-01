module Shipping
  class Shipment
    include AggregateRoot

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

    private

    on ItemAddedToShipmentPickingList do |event| 
      @picking_list.increase_item_quantity(event.data.fetch(:product_id))
    end
  end

  class PickingList
    attr_reader :items

    def initialize
      @items = []
    end

    def increase_item_quantity(product_id)
      item = find_or_add_item(product_id)
      item.increase
    end

    private
    
    def find_or_add_item(product_id)
      find_item(product_id) || add_item(product_id)
    end

    def find_item(product_id)
      items.find {|i| i.product_id == product_id }
    end
    
    def add_item(product_id)
      item = PickingListItem.new(product_id)
      items << item
      item
    end
  end

  class PickingListItem
    attr_reader :product_id, :quantity

    def initialize(product_id)
      @product_id = product_id
      @quantity = 0
    end

    def increase
      @quantity += 1
    end

    def decrease
      @quantity -= 1
    end
  end
end
