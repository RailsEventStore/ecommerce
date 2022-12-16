module Orders
  class UpdateOrderTotalValue < Infra::EventHandler
    def call(event)
      order_id = event.data.fetch(:order_id)
      ApplicationRecord.with_advisory_lock(order_id) do
        order = Order.find_or_create_by!(uid: order_id) { |order| order.state = "Draft" }

        if is_newest_value?(event, order)
          order.discounted_value = event.data.fetch(:discounted_amount)
          order.total_value = event.data.fetch(:total_amount)
          order.total_value_updated_at = event.metadata.fetch(:timestamp)
          order.save!

          broadcaster.call(order.uid, order.uid, "total_value", number_to_currency(order.total_value))
          broadcaster.call(order.uid, order.uid, "discounted_value", number_to_currency(order.discounted_value))
        end
      end

      event_store.link_event_to_stream(event, "Orders$all")
    end

    private

    def is_newest_value?(event, order)
      order.total_value_updated_at.nil? || order.total_value_updated_at < event.metadata.fetch(:timestamp)
    end

    def broadcaster
      Rails.configuration.broadcaster
    end

    def number_to_currency(number)
      ActiveSupport::NumberHelper.number_to_currency(number)
    end
  end
end
