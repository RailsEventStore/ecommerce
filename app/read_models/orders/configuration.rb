module Orders
  class Configuration
    def initialize(cqrs)
      @cqrs = cqrs
    end

    def call
      @cqrs.subscribe(OnOrderSubmitted, [Ordering::OrderSubmitted])
      @cqrs.subscribe(OnOrderExpired, [Ordering::OrderExpired])
      @cqrs.subscribe(OnOrderPaid, [Ordering::OrderPaid])
      @cqrs.subscribe(OnItemAddedToBasket, [Pricing::ItemAddedToBasket])
      @cqrs.subscribe(OnItemRemovedFromBasket, [Pricing::ItemRemovedFromBasket])
      @cqrs.subscribe(OnOrderCancelled, [Ordering::OrderCancelled])
      @cqrs.subscribe(-> (event) { update_discount(event) }, [Pricing::PercentageDiscountSet])
      @cqrs.subscribe(-> (event) { update_totals(event) }, [Pricing::OrderTotalValueCalculated])
    end

    private

    def update_discount(event)
      order = Order.find_by_uid(event.data.fetch(:order_id))
      order.percentage_discount = event.data.fetch(:amount)
      order.save!
    end

    def update_totals(event)
      order = Order.find_by_uid(event.data.fetch(:order_id))
      order.discounted_value = event.data.fetch(:discounted_amount)
      order.save!
    end
  end
end