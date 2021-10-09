module Shipping
  class PickingList
    attr_reader :items

    def initialize
      @items = []
    end

    def increase_item_quantity(product_id)
      item = find_or_add_item(product_id)
      item.increase
    end

    def decrease_item_quantity(product_id)
      item = find_item(product_id)
      item.decrease
      remove_item(item) if item.quantity.zero?
    end

    def has_item?(product_id)
      find_item(product_id)
    end

    def find_or_add_item(product_id)
      find_item(product_id) || add_item(product_id)
    end

    def find_item(product_id)
      items.find {|i| i.product_id === product_id }
    end

    private

    def add_item(product_id)
      item = PickingListItem.new(product_id)
      items << item
      item
    end

    def remove_item(item)
      items.delete(item)
    end
  end
end