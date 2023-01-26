module ClientOrders
  class ChangeProductName < Infra::EventHandler
    def call(event)
      Product.find_or_create_by(uid: event.data.fetch(:product_id)).update(
        name: event.data.fetch(:name)
      )
    end
  end
end

