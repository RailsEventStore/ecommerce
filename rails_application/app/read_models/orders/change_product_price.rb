module Orders
  class ChangeProductPrice
    def call(event)
      Product.find_or_create_by(uid: event.data.fetch(:product_id)).update(price: event.data.fetch(:price))

      event_store.link_event_to_stream(event, "Orders$all")
    end

    private

    def event_store
      Rails.configuration.event_store
    end
  end
end
