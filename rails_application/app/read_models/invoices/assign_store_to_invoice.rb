module Invoices
  class AssignStoreToInvoice
    def call(event)
      Invoice.find_or_initialize_by(order_uid: event.data.fetch(:invoice_id)).update!(store_id: event.data.fetch(:store_id))
    end
  end
end
