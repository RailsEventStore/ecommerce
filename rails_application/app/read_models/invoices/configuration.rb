module Invoices
  class Invoice < ApplicationRecord
    self.table_name = "invoices"
    has_many :invoice_items

    def total_value_with_tax
      invoice_items.sum(&:value_with_tax)
    end
  end

  class InvoiceItem < ApplicationRecord
    self.table_name = "invoice_items"
    belongs_to :invoice

    def value_with_tax
      value + (value * vat_rate / 100)
    end
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
      event_store.subscribe(MarkOrderPlaced.new, to: [Fulfillment::OrderRegistered])
      event_store.subscribe(AssignStoreToInvoice.new, to: [Stores::InvoiceRegistered])
    end
  end
end
