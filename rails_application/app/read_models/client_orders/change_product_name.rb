module ClientOrders
  class ChangeProductName < Infra::EventHandler
    def call(event)
      Product.find_by_uid(event.data.fetch(:product_id)).update(
        name: event.data.fetch(:name)
      )
    end
  end
end

