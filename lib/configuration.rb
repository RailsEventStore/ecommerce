class Configuration
  def call(event_store, command_bus)
    event_store.subscribe(Orders::OnOrderSubmitted, to: [Ordering::OrderSubmitted])
    event_store.subscribe(Orders::OnOrderExpired, to: [Ordering::OrderExpired])
    event_store.subscribe(Orders::OnOrderPaid, to: [Ordering::OrderPaid])
    event_store.subscribe(Orders::OnItemAddedToBasket, to: [Pricing::ItemAddedToBasket])
    event_store.subscribe(Orders::OnItemRemovedFromBasket, to: [Pricing::ItemRemovedFromBasket])
    event_store.subscribe(Orders::OnOrderCancelled, to: [Ordering::OrderCancelled])

    event_store.subscribe(PaymentProcess.new, to: [
      Ordering::OrderSubmitted,
      Ordering::OrderExpired,
      Ordering::OrderPaid,
      Payments::PaymentAuthorized,
      Payments::PaymentReleased,
    ])

    event_store.subscribe(OrderConfirmation.new, to: [
      Payments::PaymentAuthorized,
      Payments::PaymentCaptured
    ])

    command_bus.register(Ordering::SubmitOrder, Ordering::OnSubmitOrder.new(number_generator: Rails.configuration.number_generator.call))
    command_bus.register(Ordering::SetOrderAsExpired, Ordering::OnSetOrderAsExpired.new)
    command_bus.register(Ordering::MarkOrderAsPaid, Ordering::OnMarkOrderAsPaid.new)
    command_bus.register(Pricing::AddItemToBasket, Pricing::OnAddItemToBasket.new)
    command_bus.register(Pricing::RemoveItemFromBasket, Pricing::OnRemoveItemFromBasket.new)
    command_bus.register(Payments::AuthorizePayment, Payments::OnAuthorizePayment.new)
    command_bus.register(Payments::CapturePayment, Payments::OnCapturePayment.new)
    command_bus.register(Payments::ReleasePayment, Payments::OnReleasePayment.new)
    command_bus.register(Payments::SetPaymentAmount, Payments::OnSetPaymentAmount.new)
    command_bus.register(Ordering::CancelOrder, Ordering::OnCancelOrder.new)

    command_bus.register(Pricing::SetPrice, Pricing::SetPriceHandler.new)
    command_bus.register(Pricing::CalculateTotalValue, Pricing::OnCalculateTotalValue.new)

    command_bus.register(ProductCatalog::RegisterProduct, ProductCatalog::ProductRegistrationHandler.new)
    event_store.subscribe(ProductCatalog::AssignPriceToProduct.new, to: [Pricing::PriceSet])

    command_bus.register(Crm::RegisterCustomer, Crm::CustomerRegistrationHandler.new)

    event_store.subscribe(
      -> (event) { command_bus.call(Pricing::CalculateTotalValue.new(order_id: event.data.fetch(:order_id)))},
      to: [Ordering::OrderSubmitted])

    event_store.subscribe(
      -> (event) { command_bus.call(
        Payments::SetPaymentAmount.new(
          order_id: event.data.fetch(:order_id),
          amount: event.data.fetch(:amount)
      ))},
      to: [Pricing::OrderTotalValueCalculated])
  end
end
