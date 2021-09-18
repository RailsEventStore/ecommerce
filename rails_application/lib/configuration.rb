require_relative "../../infra/lib/infra"
require_relative "../../ecommerce/ordering/lib/ordering"
require_relative "../../ecommerce/pricing/lib/pricing"
require_relative "../../ecommerce/product_catalog/lib/product_catalog"
require_relative "../../ecommerce/crm/lib/crm"
require_relative "../../ecommerce/payments/lib/payments"
require_relative "../../ecommerce/inventory/lib/inventory"
require_relative "customer_repository"
require_relative "product_repository"

class Configuration
  def call(event_store, command_bus)
    [
      RailsEventStore::LinkByEventType.new,
      RailsEventStore::LinkByCorrelationId.new,
      RailsEventStore::LinkByCausationId.new
    ].each { |h| event_store.subscribe_to_all_events(h) }

    cqrs = Infra::Cqrs.new(event_store, command_bus)
    customer_repository = CustomerRepository.new
    product_repository = ProductRepository.new
    number_generator = Rails.configuration.number_generator
    payment_gateway = Rails.configuration.payment_gateway

    [
      Orders::Configuration.new,
      Products::Configuration.new(product_repository),
      Ordering::Configuration.new(number_generator),
      Pricing::Configuration.new,
      Payments::Configuration.new(payment_gateway),
      ProductCatalog::Configuration.new(product_repository),
      Crm::Configuration.new(customer_repository),
      Inventory::Configuration.new
    ].each { |c| c.call(event_store, command_bus) }
    cqrs.subscribe(
      PaymentProcess.new,
      [
        Ordering::OrderSubmitted,
        Ordering::OrderExpired,
        Ordering::OrderPaid,
        Payments::PaymentAuthorized,
        Payments::PaymentReleased
      ]
    )

    cqrs.subscribe(
      OrderConfirmation.new,
      [Payments::PaymentAuthorized, Payments::PaymentCaptured]
    )

    cqrs.subscribe(
      ProductCatalog::AssignPriceToProduct.new(product_repository),
      [Pricing::PriceSet]
    )

    cqrs.subscribe(
      ->(event) do
        cqrs.run(
          Pricing::CalculateTotalValue.new(
            order_id: event.data.fetch(:order_id)
          )
        )
      end,
      [Ordering::OrderSubmitted]
    )

    cqrs.subscribe(
      ->(event) do
        cqrs.run(
          Payments::SetPaymentAmount.new(
            order_id: event.data.fetch(:order_id),
            amount: event.data.fetch(:discounted_amount).to_f
          )
        )
      end,
      [Pricing::OrderTotalValueCalculated]
    )

    cqrs.subscribe(
      ->(event) do
        cqrs.run(
          Inventory::AdjustReservation.new(
            order_id: event.data.fetch(:order_id),
            product_id: event.data.fetch(:product_id),
            quantity: 1
          )
        )
      end,
      [Pricing::ItemAddedToBasket]
    )

    cqrs.subscribe(
      ->(event) do
        cqrs.run(
          Inventory::AdjustReservation.new(
            order_id: event.data.fetch(:order_id),
            product_id: event.data.fetch(:product_id),
            quantity: -1
          )
        )
      end,
      [Pricing::ItemRemovedFromBasket]
    )

    cqrs.subscribe(
      ->(event) do
        cqrs.run(
          Inventory::SubmitReservation.new(
            order_id: event.data.fetch(:order_id)
          )
        )
      end,
      [Ordering::OrderSubmitted]
    )

    cqrs.subscribe(
      ->(event) do
        cqrs.run(
          Inventory::CompleteReservation.new(
            order_id: event.data.fetch(:order_id)
          )
        )
      end,
      [Ordering::OrderPaid]
    )

    cqrs.subscribe(
      ->(event) do
        cqrs.run(
          Inventory::CancelReservation.new(
            order_id: event.data.fetch(:order_id)
          )
        )
      end,
      [Ordering::OrderCancelled]
    )

    cqrs.subscribe(
      ->(event) do
        cqrs.run(
          Inventory::CancelReservation.new(
            order_id: event.data.fetch(:order_id)
          )
        )
      end,
      [Ordering::OrderExpired]
    )
  end
end
