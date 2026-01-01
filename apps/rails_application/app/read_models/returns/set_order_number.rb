module Returns
  class SetOrderNumber
    def call(event)
      order_id = event.data.fetch(:order_id)
      order_number = event.data.fetch(:order_number)

      Return.where(order_uid: order_id).update_all(order_number: order_number)
    end
  end
end
