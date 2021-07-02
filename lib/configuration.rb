class Configuration
  def call(event_store, command_bus)
    cqrs = Cqrs.new(event_store, command_bus)

    Orders::Configuration.new(cqrs).call
    Ordering::Configuration.new(cqrs).call
    Pricing::Configuration.new(cqrs).call
    Payments::Configuration.new(cqrs).call

    cqrs.subscribe(PaymentProcess.new, [
      Ordering::OrderSubmitted,
      Ordering::OrderExpired,
      Ordering::OrderPaid,
      Payments::PaymentAuthorized,
      Payments::PaymentReleased,
    ])

    cqrs.subscribe(OrderConfirmation.new, [
      Payments::PaymentAuthorized,
      Payments::PaymentCaptured
    ])

    cqrs.register(ProductCatalog::RegisterProduct, ProductCatalog::ProductRegistrationHandler.new)
    cqrs.subscribe(ProductCatalog::AssignPriceToProduct.new, [Pricing::PriceSet])

    cqrs.register(Crm::RegisterCustomer, Crm::CustomerRegistrationHandler.new)

    cqrs.subscribe(
      -> (event) { cqrs.run(Pricing::CalculateTotalValue.new(order_id: event.data.fetch(:order_id)))},
      [Ordering::OrderSubmitted])

    cqrs.subscribe(
      -> (event) { cqrs.run(
        Payments::SetPaymentAmount.new(
          order_id: event.data.fetch(:order_id),
          amount: event.data.fetch(:amount)
        ))},
      [Pricing::OrderTotalValueCalculated])
  end
end
