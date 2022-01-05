module Invoicing
  class AddInvoiceItemHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
      @catalog = InvoiceItemTitleCatalog.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Invoice, command.invoice_id) do |invoice|
        title = @catalog.invoice_item_title_for(command.product_id)
        invoice.add_item(command.product_id, title, command.unit_price, command.vat_rate, command.quantity)
      end
    end
  end

  class SetDateHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def set_disposal_date(command)
      @repository.with_aggregate(Invoice, command.invoice_id) do |invoice|
        invoice.set_disposal_date(command.disposal_date)
      end
    end

    def set_payment_date(command)
      @repository.with_aggregate(Invoice, command.invoice_id) do |invoice|
        invoice.set_payment_date(command.payment_date)
      end
    end
  end

  class SetProductNameDisplayedOnInvoiceHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Product, command.product_id) do |product|
        product.set_name_displayed(command.name_displayed)
      end
    end
  end
end