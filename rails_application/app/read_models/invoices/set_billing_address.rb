module Invoices
  class SetBillingAddress < Infra::EventHandler
    def call(event)
      invoice = Invoice.find_or_initialize_by(order_uid: event.data.fetch(:invoice_id))
      invoice.address_present = true
      invoice.tax_id_number = event.data.fetch(:tax_id_number)
      postal_address = event.data.fetch(:postal_address)
      invoice.address_line_1 = postal_address.fetch(:line_1)
      invoice.address_line_2 = postal_address.fetch(:line_2)
      invoice.address_line_3 = postal_address.fetch(:line_3)
      invoice.address_line_4 = postal_address.fetch(:line_4)
      invoice.save!
    end
  end
end
