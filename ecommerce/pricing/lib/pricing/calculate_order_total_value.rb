module Pricing
  class CalculateOrderTotalValue
    def call(event)
      items = []
      discounts = []
      events =
        event_store
          .read
          .stream("Pricing::Offer$#{event.data.fetch(:order_id)}")
          .to_a
      events.each do |event|
        case event
        when PriceItemAdded
          items << {
            product_id: event.data.fetch(:product_id),
            base_price: event.data.fetch(:base_price),
            price: event.data.fetch(:base_price)
          }
        when PriceItemRemoved
          index =
            items.index do |i|
              i[:product_id] == event.data[:product_id] &&
                i[:price] == event.data[:price]
            end
          items.delete_at(index) if index
        when PercentageDiscountSet
          discounts << {
            type: event.data.fetch(:type),
            amount: event.data.fetch(:amount)
          }
        when PercentageDiscountChanged
          discounts =
            discounts.reject do |discount|
              discount[:type] == event.data.fetch(:type)
            end
          discounts << {
            type: event.data.fetch(:type),
            amount: event.data.fetch(:amount)
          }
        when PercentageDiscountRemoved
          discounts =
            discounts.reject do |discount|
              discount[:type] == event.data.fetch(:type)
            end
        when ProductMadeFreeForOrder
          item =
            items.find do |i|
              i[:product_id] == event.data.fetch(:product_id) && i[:price] > 0
            end
          item[:price] = 0.0 if item
        when FreeProductRemovedFromOrder
          item =
            items.find do |i|
              i[:product_id] == event.data.fetch(:product_id) && i[:price] == 0
            end
          item[:price] = item[:base_price] if item
        end
      end

      total_amount = items.sum { |item| item[:base_price] }
      discounted_amount = items.sum { |item| item[:price] }
      discounts.each do |discount|
        discounted_amount -= discounted_amount * (discount[:amount] / 100)
      end

      event_store.publish(
        OrderTotalValueCalculated.new(
          data: {
            order_id: event.data.fetch(:order_id),
            total_amount:,
            discounted_amount:
          }
        )
      )
    end

    private

    def event_store
      Pricing.event_store
    end
  end
end
