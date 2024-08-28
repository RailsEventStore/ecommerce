module ClientOrders
  class UpdateProductAvailability
    def call(event)
      Product.find_by(uid: event.data.fetch(:product_id)).update(available: event.data.fetch(:available))
    end
  end
end
