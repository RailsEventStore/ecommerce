module Invoices
  class CreateInvoiceItem < Infra::EventHandler
    def call(event)
      invoice = Invoice.find_or_initialize_by(order_uid: event.data.fetch(:invoice_id))

      item = InvoiceItem.create(
        invoice: invoice,
        name: event.data.fetch(:title),
        vat_rate: event.data.fetch(:vat_rate).fetch(:rate),
        unit_price: event.data.fetch(:unit_price),
        quantity: event.data.fetch(:quantity),
        value: event.data.fetch(:unit_price) * event.data.fetch(:quantity)
      )
      invoice.total_value = (invoice.total_value || 0) + item.value
      invoice.save!
    end
  end
end
