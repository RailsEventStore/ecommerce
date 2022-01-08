module Invoicing
  class InvoiceService
    def initialize(event_store, number_generator = InvoiceNumberGenerator.new(event_store))
      @repository = Infra::AggregateRootRepository.new(event_store)
      @titles_catalog = InvoiceItemTitleCatalog.new(event_store)
      @number_generator = number_generator
    end

    def add_item(command)
      with_invoice(command.invoice_id) do |invoice|
        title = @titles_catalog.invoice_item_title_for_product(command.product_id)
        invoice.add_item(command.product_id, title, command.unit_price, command.vat_rate, command.quantity)
      end
    end

    def set_payment_date(command)
      with_invoice(command.invoice_id) do |invoice|
        invoice.set_payment_date(command.payment_date)
      end
    end

    def set_billing_address(command)
      with_invoice(command.invoice_id) do |invoice|
        invoice.set_billing_address(command.tax_id_number, command.postal_address)
      end
    end

    def issue(command)
      with_invoice(command.invoice_id) do |invoice|
        invoice_number = @number_generator.call(command.issue_date)
        invoice.issue(command.issue_date, invoice_number)
      end
    end

    private

    def with_invoice(invoice_id)
      @repository.with_aggregate(Invoice, invoice_id) do |invoice|
        yield(invoice)
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