module Pricing
  class Order
    include AggregateRoot

    def initialize(id)
      @id = id
      @product_ids = []
    end

    def add_item(product_id)
      apply ItemAddedToBasket.new(
              data: {
                order_id: @id,
                product_id: product_id
              }
            )
    end

    def remove_item(product_id)
      apply ItemRemovedFromBasket.new(
              data: {
                order_id: @id,
                product_id: product_id
              }
            )
    end

    def calculate_total_value(pricing_catalog, percentage_discount)
      total_value =
        @product_ids.sum { |product_id| pricing_catalog.price_for(product_id) }
      discounted_value = percentage_discount.apply(total_value)
      apply(
        OrderTotalValueCalculated.new(
          data: {
            order_id: @id,
            total_amount: total_value,
            discounted_amount: discounted_value
          }
        )
      )
    end

    on ItemAddedToBasket do |event|
      @product_ids << event.data.fetch(:product_id)
    end

    on ItemRemovedFromBasket do |event|
      @product_ids.delete(event.data.fetch(:product_id))
    end

    on OrderTotalValueCalculated do |event|
    end
  end
end
