module Orders
  class AssignStoreToOrder
    def call(event)
      Order.find_by!(uid: event.data.fetch(:order_id)).update!(store_id: event.data.fetch(:store_id))
    end
  end
end
