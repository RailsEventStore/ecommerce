module Orders
  class ChangeProductPrice < Infra::EventHandler
    def call(event)
      Product.find_by_uid(event.data.fetch(:product_id)).update(price: event.data.fetch(:price))

      event_store.link_event_to_stream(event, "Orders$all")
    end
  end
end
