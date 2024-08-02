module ClientOrders
  class RegisterProduct
    def call(event)
      Product.find_or_create_by(uid: event.data.fetch(:product_id))
    end
  end
end
