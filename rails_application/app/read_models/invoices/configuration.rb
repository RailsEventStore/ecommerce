module Invoices
  class Invoice < ApplicationRecord
    self.table_name = "invoices"
    has_many :invoice_items
  end

  class InvoiceItem < ApplicationRecord
    self.table_name = "invoice_items"
    belongs_to :invoice
  end

  class Order < ApplicationRecord
    self.table_name = "invoices_orders"
  end

  class Configuration
    def call(cqrs)
      cqrs.subscribe(
        ->(event) { create_invoice_item(event) },
        [Invoicing::InvoiceItemAdded]
      )
      cqrs.subscribe(
        ->(event) { set_billing_address(event) },
        [Invoicing::BillingAddressSet]
      )
      cqrs.subscribe(
        ->(event) { set_payment_date(event) },
        [Invoicing::InvoicePaymentDateSet]
      )
      cqrs.subscribe(
        ->(event) { mark_as_issued(event) },
        [Invoicing::InvoiceIssued]
      )
      cqrs.subscribe(
        ->(event) { mark_order_submitted(event) },
        [Ordering::OrderSubmitted]
      )
    end

    private

    def set_billing_address(event)
      with_invoice(event.data.fetch(:invoice_id)) do |invoice|
        invoice.address_present = true
        invoice.tax_id_number = event.data.fetch(:tax_id_number)
        postal_address = event.data.fetch(:postal_address)
        invoice.address_line_1 = postal_address.fetch(:line_1)
        invoice.address_line_2 = postal_address.fetch(:line_2)
        invoice.address_line_3 = postal_address.fetch(:line_3)
        invoice.address_line_4 = postal_address.fetch(:line_4)
      end
    end

    def create_invoice_item(event)
      with_invoice(event.data.fetch(:invoice_id)) do |invoice|
        item = InvoiceItem.create(
          invoice: invoice,
          vat_rate: event.data.fetch(:vat_rate).fetch(:rate),
          unit_price: event.data.fetch(:unit_price),
          quantity: event.data.fetch(:quantity),
          value: event.data.fetch(:unit_price) * event.data.fetch(:quantity)
        )
        invoice.total_value = invoice.total_value || 0 + item.value
      end
    end

    def set_payment_date(event)
      with_invoice(event.data.fetch(:invoice_id)) do |invoice|
        invoice.payment_date = event.data.fetch(:payment_date)
      end
    end

    def mark_as_issued(event)
      with_invoice(event.data.fetch(:invoice_id)) do |invoice|
        invoice.issued = true
        invoice.issue_date = event.data.fetch(:issue_date)
        invoice.disposal_date = event.data.fetch(:disposal_date)
        invoice.number = event.data.fetch(:invoice_number)
      end
    end

    def mark_order_submitted(event)
      Order.find_or_initialize_by(uid: event.data.fetch(:order_id)).update!(submitted: true)
    end

    def with_invoice(uid)
      invoice = Invoice.find_or_initialize_by(order_uid: uid)
      yield(invoice)
      invoice.save!
    end
  end
end
