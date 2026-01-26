module Invoicing
  class Product
    include AggregateRoot

    def initialize(product_id)
      @product_id = product_id
    end

    def set_name_displayed(name)
      apply(
        ProductNameDisplayedSet.new(
          data: {
            product_id: @product_id,
            name_displayed: name
          }
        )
      )
    end

    private

    on ProductNameDisplayedSet do |event|
      @name_displayed = event.data[:name_displayed]
    end
  end
end