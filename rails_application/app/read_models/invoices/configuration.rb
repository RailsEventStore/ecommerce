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
      event_store.subscribe(CreateInvoiceItem.new, to: [Invoicing::InvoiceItemAdded])
      event_store.subscribe(SetBillingAddress.new, to: [Invoicing::BillingAddressSet])
      event_store.subscribe(SetPaymentDate.new, to: [Invoicing::InvoicePaymentDateSet])
      event_store.subscribe(MarkAsIssued.new, to: [Invoicing::InvoiceIssued])
      # event_store.subscribe(MarkOrderPlaced.new, to: [Ordering::OrderPlaced])
    end
  end
end
