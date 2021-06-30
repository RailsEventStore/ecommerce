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
    end
  end
end