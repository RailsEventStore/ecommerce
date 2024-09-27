module ClientOrders

  class ConfirmOrder
    def call(event)
      order = Order.find_by(order_uid: event.data.fetch(:order_id))
      order.state = "Paid"
      order.save!
    end
  end

  class SubmitOrder
    def call(event)
      order = Order.find_or_create_by(order_uid: event.data.fetch(:order_id))
      order.number = event.data.fetch(:order_number)
      order.state = "Submitted"
      order.save!
    end
  end

  class UpdateDiscount
    def call(event)
      order = Order.find_or_create_by!(order_uid: event.data.fetch(:order_id))
      order.percentage_discount = event.data.fetch(:amount)
      order.save!
    end
  end

  class UpdateOrderTotalValue
    def call(event)
      order = Order.find_or_create_by!(order_uid: event.data.fetch(:order_id)) { |order| order.state = "Draft" }
      order.discounted_value = event.data.fetch(:discounted_amount)
      order.total_value = event.data.fetch(:total_amount)
      order.save!
    end
  end

  class UpdatePaidOrdersSummary
    def call(event)
      order = Order.find_by(order_uid: event.data.fetch(:order_id))
      client = Client.where(uid: order.client_uid).first
      client.update(paid_orders_summary: client.paid_orders_summary + order.discounted_value)
    end
  end

  class ExpireOrder
    def call(event)
      order = Order.find_by(order_uid: event.data.fetch(:order_id))
      order.state = "Expired"
      order.save!
    end
  end

  class CancelOrder
    def call(event)
      order = Order.find_by(order_uid: event.data.fetch(:order_id))
      order.state = "Cancelled"
      order.save!
    end
  end

  class AssignCustomerToOrder
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

  class ResetDiscount
    def call(event)
      order = Order.find_by(order_uid: event.data.fetch(:order_id))
      order.percentage_discount = nil
      order.save!
    end
  end
end
