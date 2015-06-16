module Denormalizers
  class ItemAddedToBasket
    def handle_event(event)
      item = find(event.order_id, event.product_id) ||
             create(event.order_id, event.product_id)
      item.quantity += 1
      item.save!
    end

    private
    def find(order_uid, product_id)
      ::OrderLine.where({order_uid: order_uid, product_id: product_id}).first
    end

    def create(order_uid, product_id)
      ::OrderLine.new.tap do |i|
        i.order_uid = order_uid
        i.product_id = product_id
        i.product_name = Product.find(product_id).name
        i.quantity = 0
      end
    end
  end
end
