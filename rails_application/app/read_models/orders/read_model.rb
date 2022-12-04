module Orders
  class ReadModel < Infra::EventHandler
    def broadcast_update(order_id, product_id, target, content)
      Turbo::StreamsChannel.broadcast_update_to(
        "orders_order_#{order_id}",
        target: "orders_order_#{product_id}_#{target}",
        html: content)
    end

    def link_event_to_stream(event)
      event_store.link_event_to_stream(event, "Orders$all")
    end
  end
end