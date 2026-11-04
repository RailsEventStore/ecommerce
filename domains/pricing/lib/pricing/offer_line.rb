module Pricing
  class OfferLine
    include AggregateRoot

    IsEmpty = Class.new(StandardError)

    def initialize(id)
      @order_id, @product_id = id.split(":")
      @prices = []
    end

    def add_item(price)
      apply PriceItemAdded.new(data: {
        order_id: @order_id,
        product_id: @product_id,
        price: price
      })
    end

    def remove_item
      raise IsEmpty if @prices.empty?
      apply PriceItemRemoved.new(data: {
        order_id: @order_id,
        product_id: @product_id,
        price: @prices.min
      })
    end

    private

    on PriceItemAdded do |event|
      @prices << event.data.fetch(:price)
    end

    on PriceItemRemoved do |event|
      @prices.delete_at(@prices.index(event.data.fetch(:price)))
    end
  end
end
