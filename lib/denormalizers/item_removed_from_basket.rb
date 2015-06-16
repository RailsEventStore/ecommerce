module Denormalizers
  class ItemRemovedFromBasket
    def handle_event(event)
      item = find(event.order_id, event.product_id)
      item.quantity -= 1
      item.quantity > 0 ? item.save! : item.destroy!
    end

    private
    def find(order_uid, product_id)
      ::OrderLine.where({order_uid: order_uid, product_id: product_id}).first
    end
  end
end
