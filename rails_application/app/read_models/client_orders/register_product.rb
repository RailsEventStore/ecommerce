module ClientOrders
  class RegisterProduct < Infra::EventHandler
    def call(event)
      Product.create(uid: event.data.fetch(:product_id))
    end
  end
end

