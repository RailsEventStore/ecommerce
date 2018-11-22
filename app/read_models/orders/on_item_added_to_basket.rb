module Orders
  class OnItemAddedToBasket
    def call(event)
      create_draft_order(event.data[:order_id])
      item = find(event.data[:order_id], event.data[:product_id]) ||
             create(event.data[:order_id], event.data[:product_id])
      item.quantity += 1
      item.save!
    end

    private
    def create_draft_order(uid)
      return if Order.where(uid: uid).exists?
      Order.create!(
        uid: uid,
        state: "Draft",
      )
    end

    def find(order_uid, product_id)
      OrderLine.where({order_uid: order_uid, product_id: product_id}).first
    end

    def create(order_uid, product_id)
      OrderLine.new.tap do |i|
        i.order_uid = order_uid
        i.product_id = product_id
        i.product_name = Product.find(product_id).name
        i.quantity = 0
      end
    end
  end
end
