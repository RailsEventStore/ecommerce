module Invoicing
  class GenerateInvoiceHandler
    def call(cmd)
    end
  end

  class AddInvoiceItemHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Invoice, command.invoice_id) do |invoice|
        invoice.add_item(command.product_id, command.unit_price, command.vat_rate, command.quantity)
      end
    end
  end
end