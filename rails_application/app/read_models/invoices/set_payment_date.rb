module Invoices
  class SetPaymentDate < Infra::EventHandler
    def call(event)
      invoice = Invoice.find_or_initialize_by(order_uid: event.data.fetch(:invoice_id))
      invoice.payment_date = event.data.fetch(:payment_date)
      invoice.save!
    end
  end
end