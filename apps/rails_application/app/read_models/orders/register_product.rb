module Orders
  class RegisterProduct
    def call(event)
      Product.create(uid: event.data.fetch(:product_id))

      event_store.link_event_to_stream(event, "Orders$all")
    end

    private

    def event_store
      Rails.configuration.event_store
    end
  end
end
