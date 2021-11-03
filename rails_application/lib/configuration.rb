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

      configure_bounded_contexts(cqrs, customer_repository, number_generator, payment_gateway, product_repository)
      enable_release_payment_process(cqrs)
      enable_order_confirmation_process(cqrs)
      assign_price_in_product_catalog(cqrs, product_repository)
      calculate_total_value_when_order_submitted(cqrs)
      notify_payments_about_order_total_value(cqrs)
      enable_inventory_sync_from_ordering(cqrs)
      enable_shipment_sync(cqrs)
      enable_shipment_process(cqrs)
    end

    private

    def enable_shipment_process(cqrs)
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

    def enable_shipment_sync(cqrs)
      cqrs.subscribe(
        ->(event) do
          cqrs.run(
            Shipping::AddItemToShipmentPickingList.new(
              order_id: event.data.fetch(:order_id),
              product_id: event.data.fetch(:product_id)
            )
          )
        end,
        [Pricing::ItemAddedToBasket]
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
        [Pricing::ItemRemovedFromBasket]
      )
    end

    def notify_payments_about_order_total_value(cqrs)
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
    end

    def calculate_total_value_when_order_submitted(cqrs)
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
    end

    def assign_price_in_product_catalog(cqrs, product_repository)
      cqrs.subscribe(
        ProductCatalog::AssignPriceToProduct.new(product_repository),
        [Pricing::PriceSet]
      )
    end

    def enable_inventory_sync_from_ordering(cqrs)
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

    def enable_order_confirmation_process(cqrs)
      cqrs.subscribe(
        OrderConfirmation.new,
        [Payments::PaymentAuthorized, Payments::PaymentCaptured]
      )
    end

    def enable_release_payment_process(cqrs)
      cqrs.subscribe(
        ReleasePaymentProcess.new,
        [
          Ordering::OrderSubmitted,
          Ordering::OrderExpired,
          Ordering::OrderPaid,
          Payments::PaymentAuthorized,
          Payments::PaymentReleased
        ]
      )
    end

    def configure_bounded_contexts(cqrs, customer_repository, number_generator, payment_gateway, product_repository)
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
    end
  end
end