module Invoices
  class MarkAsIssued < Infra::EventHandler
    def call(event)
      invoice = Invoice.find_or_initialize_by(order_uid: event.data.fetch(:invoice_id))
      invoice.issued = true
      invoice.issue_date = event.data.fetch(:issue_date)
      invoice.disposal_date = event.data.fetch(:disposal_date)
      invoice.number = event.data.fetch(:invoice_number)
      invoice.save!
    end
  end
end
