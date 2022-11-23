module Invoices
  class MarkOrderSubmitted < Infra::EventHandler
    def call(event)
      invoice = Invoice.find_or_initialize_by(order_uid: event.data.fetch(:order_id))
      Order.find_or_initialize_by(uid: event.data.fetch(:order_id)).update!(submitted: true)
      invoice.save!
    end
  end
end
