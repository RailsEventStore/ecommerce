module Orders
  class UpdateOrderTotalValue
    def initialize(free_product_saving_renderer)
      @free_product_saving_renderer = free_product_saving_renderer
    end

    def call(event)
      order_id = event.data.fetch(:order_id)
      order = Order.find_or_create_by!(uid: order_id)

      if is_newest_value?(event, order)
        order.discounted_value = event.data.fetch(:discounted_amount)
        order.total_value = event.data.fetch(:total_amount)
        order.free_product_id = event.data.fetch(:free_product_id, nil)
        order.free_product_saving = event.data.fetch(:free_product_saving, 0)
        order.total_value_updated_at = event.metadata.fetch(:timestamp)
        order.save!

        broadcaster.call(order.uid, order.uid, "total_value", number_to_currency(order.total_value))
        broadcaster.call(order.uid, order.uid, "discounted_value", number_to_currency(order.discounted_value))
        broadcaster.call(order.uid, order.uid, "free_product_saving_row", free_product_saving_row(order))
      end

      event_store.link_event_to_stream(event, "Orders$all")
    end

    private

    def event_store
      Rails.configuration.event_store
    end

    def is_newest_value?(event, order)
      order.total_value_updated_at.nil? || order.total_value_updated_at < event.metadata.fetch(:timestamp)
    end

    def broadcaster
      Rails.configuration.broadcaster
    end

    def number_to_currency(number)
      ActiveSupport::NumberHelper.number_to_currency(number)
    end

    def free_product_saving_row(order)
      return "" unless order.free_product_id

      @free_product_saving_renderer.call(number_to_currency(order.free_product_saving))
    end
  end
end
