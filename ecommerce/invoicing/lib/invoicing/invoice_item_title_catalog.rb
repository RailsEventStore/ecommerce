module Invoicing
  class InvoiceItemTitleCatalog
    def initialize(event_store)
      @event_store = event_store
    end

    def invoice_item_title_for_product(product_id)
      @event_store
        .read
        .of_type(ProductNameDisplayedSet)
        .to_a
        .filter { |e| e.data.fetch(:product_id).eql?(product_id) }
        .last
        .data
        .fetch(:name_displayed)
    end
  end
end