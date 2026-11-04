module ClientOrders
  module OrderHandlers
    class DraftOrder
      def call(event)
        Order.create!(order_uid: event.data.fetch(:order_id), state: "Draft")
      end
    end

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
        order.time_promotion_discount = { discount_value: event.data.fetch(:amount).to_f, type: Pricing::Discounts::TIME_PROMOTION_DISCOUNT }
        order.save!
      end
    end

    class UpdateOrderTotalValue
      def call(event)
        order = Order.find_or_create_by!(order_uid: event.data.fetch(:order_id)) { |order| order.state = "Draft" }
        order.discounted_value = event.data.fetch(:discounted_amount)
        order.total_value = event.data.fetch(:total_amount)
        order.free_product_id = event.data.fetch(:free_product_id, nil)
        order.free_product_saving = event.data.fetch(:free_product_saving, 0)
        order.discounted_line_values = event.data.fetch(:items, nil).to_h { |item| [item.fetch(:product_id), item.fetch(:amount)] }
        order.save!

        broadcast_update(order, order.order_uid, "total_value", number_to_currency(order.value_before_discounts))
        broadcast_update(order, order.order_uid, "savings", number_to_currency(order.savings))
        broadcast_update(order, order.order_uid, "discounted_value", number_to_currency(order.discounted_value))
        broadcast_update(order, order.order_uid, "free_product_saving_row", free_product_saving_row(order))
        (order.discounted_line_values.keys | order.discounted_line_values_before_last_save.keys).each do |product_id|
          broadcast_update(order, product_id, "discounted_value", number_to_currency(order.discounted_line_value(product_id)) || "—")
        end
      end

      private

      def broadcast_update(order, target_id, target, content)
        Turbo::StreamsChannel.broadcast_update_to(
          "client_orders_#{order.order_uid}",
          target: "client_orders_#{target_id}_#{target}",
          attributes: { "data-discounts-order" => order.order_uid, "data-discounts-version" => order.discounts_version },
          html: content)
      end

      def number_to_currency(number)
        ActiveSupport::NumberHelper.number_to_currency(number)
      end

      def free_product_saving_row(order)
        Rendering::FreeProductSaving.call(order.free_product_saving) if order.free_product_id
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
