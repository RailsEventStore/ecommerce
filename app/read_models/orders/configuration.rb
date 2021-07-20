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
    end

    private

    def update_discount(event)
      order = Order.find_by_uid(event.data.fetch(:order_id))
      order.percentage_discount = event.data.fetch(:amount)
      order.save!
    end
  end
end