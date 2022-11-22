module ClientOrders
  class AssignCustomerToOrder < Infra::EventHandler
    def call(event)
      order_uid = event.data.fetch(:order_id)
      order = Order.find_by(order_uid: order_uid)

      if order.nil?
        order = Order.create!(order_uid: order_uid, state: "Draft")
      end

      order.client_uid = event.data.fetch(:customer_id)
      order.save!
    end
  end
end
