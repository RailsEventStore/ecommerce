module Orders
  class OnItemAddedToBasket
    def call(event)
      order_id = event.data.fetch(:order_id)
      create_draft_order(order_id)
      item = find(order_id, event.data.fetch(:product_id)) ||
             create(order_id, event.data.fetch(:product_id))
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
      Order.find_by_uid(order_uid).order_lines.where(product_id: product_id).first
    end

    def create(order_uid, product_id)
      OrderLine.new do |i|
        i.order_uid = order_uid
        i.product_id = product_id
        product = ProductCatalog::Product.find(product_id)
        i.product_name = product.name
        i.price        = product.price
        i.quantity     = 0
      end
    end
  end
end
