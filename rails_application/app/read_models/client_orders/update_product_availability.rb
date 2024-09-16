module ClientOrders
  class UpdateProductAvailability
    def call(event)
      product = Product.find_by(uid: event.data.fetch(:product_id))
      available = event.data.fetch(:available)

      product.update(available: available.positive?)
    end
  end
end
