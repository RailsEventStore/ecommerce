module ClientOrders
  class ChangeProductPrice < Infra::EventHandler
    def call(event)
      Product.find_by_uid(event.data.fetch(:product_id)).update(price: event.data.fetch(:price))
    end
  end
end
