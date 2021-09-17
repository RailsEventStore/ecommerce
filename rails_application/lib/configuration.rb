require_relative "../../infra/lib/infra"
require_relative "../../ecommerce/ordering/lib/ordering"
require_relative "../../ecommerce/pricing/lib/pricing"
require_relative "../../ecommerce/product_catalog/lib/product_catalog"
require_relative "../../ecommerce/crm/lib/crm"
require_relative "../../ecommerce/payments/lib/payments"
require_relative "../../ecommerce/inventory/lib/inventory"
require_relative 'customer_repository'

class Configuration
  def call(event_store, command_bus)
    event_store.subscribe_to_all_events(RailsEventStore::LinkByEventType.new)
    event_store.subscribe_to_all_events(RailsEventStore::LinkByCorrelationId.new)
    event_store.subscribe_to_all_events(RailsEventStore::LinkByCausationId.new)

    cqrs = Infra::Cqrs.new(event_store, command_bus)

    Orders::Configuration.new(cqrs).call
    Products::Configuration.new(cqrs).call

    Ordering::Configuration.new(cqrs, event_store, Rails.configuration.number_generator).call
    Pricing::Configuration.new(cqrs, event_store).call
    Payments::Configuration.new(cqrs, event_store).call
    ProductCatalog::Configuration.new(cqrs).call
    Crm::Configuration.new(cqrs, CustomerRepository.new).call
    Inventory::Configuration.new(cqrs, event_store).call

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

    cqrs.subscribe(ProductCatalog::AssignPriceToProduct.new, [Pricing::PriceSet])

    cqrs.subscribe(
      -> (event) { cqrs.run(Pricing::CalculateTotalValue.new(order_id: event.data.fetch(:order_id)))},
      [Ordering::OrderSubmitted])

    cqrs.subscribe(
      -> (event) { cqrs.run(
        Payments::SetPaymentAmount.new(order_id: event.data.fetch(:order_id), amount: event.data.fetch(:discounted_amount).to_f))},
      [Pricing::OrderTotalValueCalculated])

    cqrs.subscribe(
      -> (event) { cqrs.run(
        Inventory::AdjustReservation.new(order_id: event.data.fetch(:order_id), product_id: event.data.fetch(:product_id), quantity: 1))},
      [Pricing::ItemAddedToBasket])

    cqrs.subscribe(
      -> (event) { cqrs.run(
        Inventory::AdjustReservation.new(order_id: event.data.fetch(:order_id), product_id: event.data.fetch(:product_id), quantity: -1))},
      [Pricing::ItemRemovedFromBasket])

    cqrs.subscribe(
      -> (event) { cqrs.run(
        Inventory::SubmitReservation.new(order_id: event.data.fetch(:order_id))) },
      [Ordering::OrderSubmitted])

    cqrs.subscribe(
      -> (event) { cqrs.run(
        Inventory::CompleteReservation.new(order_id: event.data.fetch(:order_id))) },
      [Ordering::OrderPaid])

    cqrs.subscribe(
      -> (event) { cqrs.run(
        Inventory::CancelReservation.new(order_id: event.data.fetch(:order_id))) },
      [Ordering::OrderCancelled])

    cqrs.subscribe(
      -> (event) { cqrs.run(
        Inventory::CancelReservation.new(order_id: event.data.fetch(:order_id))) },
      [Ordering::OrderExpired])
  end
end
