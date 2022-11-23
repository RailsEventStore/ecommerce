module Shipments
  class MarkOrderSubmitted < Infra::EventHandler
    def call(event)
      Order.find_or_initialize_by(uid: event.data.fetch(:order_id)).update!(submitted: true)
    end
  end
end
