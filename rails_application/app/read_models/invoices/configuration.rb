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
    def call(event_store)
      event_store.subscribe(CreateInvoiceItem, to: [Invoicing::InvoiceItemAdded])
      event_store.subscribe(SetBillingAddress, to: [Invoicing::BillingAddressSet])
      event_store.subscribe(SetPaymentDate, to: [Invoicing::InvoicePaymentDateSet])
      event_store.subscribe(MarkAsIssued, to: [Invoicing::InvoiceIssued])
      event_store.subscribe(MarkOrderSubmitted, to: [Ordering::OrderSubmitted])
    end
  end
end
