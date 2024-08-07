module ClientOrders
  class ChangeProductPrice
    def call(event)
      Product.find_or_create_by(uid: event.data.fetch(:product_id)).update(price: event.data.fetch(:price))
    end
  end
end
