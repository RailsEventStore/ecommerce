module Orders
  class DraftOrder
    def call(event)
      Order.create(
        uid: event.data.fetch(:order_id)
      )
    end
  end
end
