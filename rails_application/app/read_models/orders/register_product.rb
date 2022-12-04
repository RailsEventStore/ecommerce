module Orders
  class RegisterProduct < ReadModel
    def call(event)
      Product.create(uid: event.data.fetch(:product_id))

      link_event_to_stream(event)
    end
  end
end

