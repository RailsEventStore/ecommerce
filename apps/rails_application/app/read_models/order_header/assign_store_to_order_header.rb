module OrderHeader
  class AssignStoreToOrderHeader
    def call(event)
      Header.find_by!(uid: event.data.fetch(:order_id)).update!(store_id: event.data.fetch(:store_id))
    end
  end
end
