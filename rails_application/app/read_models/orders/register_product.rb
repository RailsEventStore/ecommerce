module Orders
  class RegisterProduct
    def call(event)
      Product.create(uid: event.data.fetch(:product_id))

      event_store.link_event_to_stream(event, "Orders$all")
    end
  end
end
