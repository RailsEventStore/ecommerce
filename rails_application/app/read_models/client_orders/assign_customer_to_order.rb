module ClientOrders
  class AssignCustomerToOrder < Infra::EventHandler
    def call(event)
      order = Order.find_by(order_uid: event.data.fetch(:order_id))
      unless order.nil?
        order.client_uid = event.data.fetch(:customer_id)
        order.save!
      end
    end
  end
end
