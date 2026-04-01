module ClientOrders
  class RenameCustomer
    def call(event)
      Client.find_by(uid: event.data.fetch(:customer_id)).update!(name: event.data.fetch(:name))
    end
  end
end
