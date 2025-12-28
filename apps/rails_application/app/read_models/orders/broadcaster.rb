module Orders
  class Broadcaster
    def call(stream_id, target_id, target_name, content)
      Turbo::StreamsChannel.broadcast_update_to(
        "orders_order_#{stream_id}",
        target: "orders_order_#{target_id}_#{target_name}",
        html: content)
    end
  end
end