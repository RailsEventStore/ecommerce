require_relative "../../ecommerce/ordering/lib/ordering"
require_relative "../../ecommerce/pricing/lib/pricing"
require_relative "../../ecommerce/product_catalog/lib/product_catalog"
require_relative "../../ecommerce/crm/lib/crm"
require_relative "../../ecommerce/payments/lib/payments"
require_relative "../../ecommerce/inventory/lib/inventory"
require_relative "../../ecommerce/shipping/lib/shipping"
require_relative "customer_repository"
require_relative "product_repository"

module Ecommerce
  class Configuration
    def call(cqrs)
      [
        RailsEventStore::LinkByEventType.new,
        RailsEventStore::LinkByCorrelationId.new,
        RailsEventStore::LinkByCausationId.new
      ].each { |h| cqrs.subscribe_to_all_events(h) }

      customer_repository = CustomerRepository.new
      product_repository = ProductRepository.new
      number_generator = Rails.configuration.number_generator
      payment_gateway = Rails.configuration.payment_gateway

      [
        Orders::Configuration.new(product_repository, customer_repository),
        Products::Configuration.new(product_repository),
        Shipments::Configuration.new,
        Ordering::Configuration.new(number_generator),
        Pricing::Configuration.new,
        Payments::Configuration.new(payment_gateway),
        ProductCatalog::Configuration.new(product_repository),
        Crm::Configuration.new(customer_repository),
        Inventory::Configuration.new,
        Shipping::Configuration.new
      ].each { |c| c.call(cqrs) }
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
            Pricing::AddPriceItem.new(
              order_id: event.data.fetch(:order_id),
              product_id: event.data.fetch(:product_id)
            )
          )
        end,
        [Ordering::ItemAddedToBasket]
      )

      cqrs.subscribe(
        ->(event) do
          cqrs.run(
            Pricing::RemovePriceItem.new(
              order_id: event.data.fetch(:order_id),
              product_id: event.data.fetch(:product_id)
            )
          )
        end,
        [Ordering::ItemRemovedFromBasket]
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
            Inventory::SubmitReservation.new(
              order_id: event.data.fetch(:order_id),
              reservation_items: event.data.fetch(:order_lines)
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
        [Ordering::OrderCancelled, Ordering::OrderExpired]
      )

      cqrs.subscribe(
        ->(event) do
          cqrs.run(
            Shipping::AddItemToShipmentPickingList.new(
              order_id: event.data.fetch(:order_id),
              product_id: event.data.fetch(:product_id)
            )
          )
        end,
        [Ordering::ItemAddedToBasket]
      )

      cqrs.subscribe(
        ->(event) do
          cqrs.run(
            Shipping::RemoveItemFromShipmentPickingList.new(
              order_id: event.data.fetch(:order_id),
              product_id: event.data.fetch(:product_id)
            )
          )
        end,
        [Ordering::ItemRemovedFromBasket]
      )

      cqrs.subscribe(
        ShipmentProcess.new,
        [
          Shipping::ShippingAddressAddedToShipment,
          Shipping::ShipmentSubmitted,
          Ordering::OrderSubmitted,
          Ordering::OrderPaid
        ]
      )
    end
  end
end