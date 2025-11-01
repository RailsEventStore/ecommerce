module Orders
  class DraftOrder
    def call(event)
      Order.create(
        uid: event.data.fetch(:order_id),
        state: "Draft"
      )
    end
  end
end
