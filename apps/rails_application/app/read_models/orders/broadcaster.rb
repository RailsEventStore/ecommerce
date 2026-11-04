module Orders
  class Broadcaster
    def call(stream_id, target_id, target_name, content, version: nil)
      Turbo::StreamsChannel.broadcast_update_to(
        "orders_order_#{stream_id}",
        target: "orders_order_#{target_id}_#{target_name}",
        attributes: { "data-discounts-order" => stream_id, "data-discounts-version" => version },
        html: content)
    end
  end
end
