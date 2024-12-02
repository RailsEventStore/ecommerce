module ClientOrders
  module OrderHandlers
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
        return unless event.data.fetch(:type) == Pricing::Discounts::GENERAL_DISCOUNT

        order = Order.find_or_create_by!(order_uid: event.data.fetch(:order_id))
        order.percentage_discount = event.data.fetch(:amount)
        order.save!
      end
    end

    class UpdateTimePromotionDiscount
      def call(event)
        return unless event.data.fetch(:type) == Pricing::Discounts::TIME_PROMOTION_DISCOUNT

        order = Order.find_or_create_by!(order_uid: event.data.fetch(:order_id))
        order.time_promotion_discount = event.data.fetch(:amount)
        order.save!
      end
    end

    class UpdateOrderTotalValue
      def call(event)
        order = Order.find_or_create_by!(order_uid: event.data.fetch(:order_id)) { |order| order.state = "Draft" }
        order.discounted_value = event.data.fetch(:discounted_amount)
        order.total_value = event.data.fetch(:total_amount)
        order.save!

        broadcast_update(order.order_uid, "total_value", number_to_currency(order.total_value))
        broadcast_update(order.order_uid, "discounted_value", number_to_currency(order.discounted_value))
      end

      private

      def broadcast_update(order_id, target, content)
        Turbo::StreamsChannel.broadcast_update_to(
          "client_orders_#{order_id}",
          target: "client_orders_#{order_id}_#{target}",
          html: content)
      end

      def number_to_currency(number)
        ActiveSupport::NumberHelper.number_to_currency(number)
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

    class RemoveDiscount
      def call(event)
        return unless event.data.fetch(:type) == Pricing::Discounts::GENERAL_DISCOUNT

        order = Order.find_by(order_uid: event.data.fetch(:order_id))
        order.percentage_discount = nil
        order.save!
      end
    end

    class RemoveTimePromotionDiscount
      def call(event)
        return unless event.data.fetch(:type) == Pricing::Discounts::TIME_PROMOTION_DISCOUNT

        order = Order.find_by(order_uid: event.data.fetch(:order_id))
        order.time_promotion_discount = nil
        order.save!
      end
    end
  end
end
