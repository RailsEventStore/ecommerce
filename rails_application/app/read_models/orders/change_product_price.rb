module Orders
  class ChangeProductPrice < Infra::EventHandler
    def call(event)
      Product.find_or_create_by(uid: event.data.fetch(:product_id)).update(price: event.data.fetch(:price))

      event_store.link_event_to_stream(event, "Orders$all")
    end
  end
end
