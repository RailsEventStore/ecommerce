require_relative "../../ordering/lib/ordering"
require_relative "../../pricing/lib/pricing"
require_relative "../../product_catalog/lib/product_catalog"
require_relative "../../crm/lib/crm"
require_relative "../../payments/lib/payments"
require_relative "../../inventory/lib/inventory"
require_relative "../../shipping/lib/shipping"
require_relative "../../taxes/lib/taxes"
require_relative "../../invoicing/lib/invoicing"
require_relative 'processes/check_availability_on_order_item_added_to_basket'
require_relative 'processes/order_confirmation'
require_relative 'processes/release_payment_process'
require_relative 'processes/shipment_process'
require_relative 'processes/determine_vat_rates_on_order_submitted'
require_relative 'processes/order_item_invoicing_process'
require_relative 'processes/sync_pricing_from_ordering'
require_relative 'processes/notify_payments_about_order_value'
require_relative 'processes/sync_shipment_from_ordering'
require_relative 'processes/sync_inventory_from_ordering'
require_relative 'processes/three_plus_one_free'

require 'math'

module Processes
  class Configuration
    def call(cqrs, event_store, command_bus)
      enable_pricing_sync_from_ordering(event_store, command_bus)
      notify_payments_about_order_total_value(event_store, command_bus)
      enable_inventory_sync_from_ordering(event_store, command_bus)
      enable_shipment_sync(event_store, command_bus)
      check_product_availability_on_adding_item_to_basket(event_store, command_bus)
      determine_vat_rates_on_order_submitted(event_store, command_bus)
      set_invoice_payment_date_when_order_confirmed(event_store, command_bus)
      enable_product_name_sync(event_store, command_bus)

      enable_release_payment_process(event_store, command_bus)
      enable_order_confirmation_process(cqrs)
      enable_shipment_process(event_store, command_bus)
      enable_order_item_invoicing_process(event_store, command_bus)
    end

    private

    def enable_shipment_process(event_store, command_bus)
      ShipmentProcess.new(event_store, command_bus)
    end

    def enable_shipment_sync(event_store, command_bus)
      SyncShipmentFromOrdering.new(event_store, command_bus)
    end

    def notify_payments_about_order_total_value(event_store, command_bus)
      NotifyPaymentsAboutOrderValue.new(event_store, command_bus)
    end

    def enable_inventory_sync_from_ordering(event_store, command_bus)
      SyncInventoryFromOrdering.new(event_store, command_bus)
    end

    def enable_pricing_sync_from_ordering(event_store, command_bus)
      SyncPricingFromOrdering.new(event_store, command_bus)
    end

    def enable_order_confirmation_process(cqrs)
      cqrs.subscribe(
        OrderConfirmation.new(cqrs),
        [Payments::PaymentAuthorized, Payments::PaymentCaptured]
      )
    end

    def enable_release_payment_process(event_store, command_bus)
      event_store.subscribe(
        ReleasePaymentProcess.new(event_store, command_bus),
        to: [
          Ordering::OrderSubmitted,
          Ordering::OrderExpired,
          Ordering::OrderConfirmed,
          Payments::PaymentAuthorized,
          Payments::PaymentReleased
        ]
      )
    end

    def enable_order_item_invoicing_process(event_store, command_bus)
      event_store.subscribe(
        OrderItemInvoicingProcess.new(event_store, command_bus),
        to: [
          Pricing::PriceItemValueCalculated,
          Taxes::VatRateDetermined
        ]
      )
    end

    def check_product_availability_on_adding_item_to_basket(event_store, command_bus)
      event_store.subscribe(
        CheckAvailabilityOnOrderItemAddedToBasket.new(command_bus),
        to: [Ordering::ItemAddedToBasket]
      )
    end

    def determine_vat_rates_on_order_submitted(event_store, command_bus)
      event_store.subscribe(
        DetermineVatRatesOnOrderSubmitted.new(command_bus),
        to: [Ordering::OrderSubmitted]
      )
    end

    def enable_product_name_sync(event_store, command_bus)
      Infra::Process.new(event_store, command_bus)
                    .call(ProductCatalog::ProductNamed, [:product_id, :name],
                          Invoicing::SetProductNameDisplayedOnInvoice, [:product_id, :name_displayed])
    end

    def set_invoice_payment_date_when_order_confirmed(event_store, command_bus)
      event_store.subscribe(
        ->(event) do
          command_bus.call(
            Invoicing::SetPaymentDate.new(
              invoice_id: event.data.fetch(:order_id),
              payment_date: Time.zone.at(event.metadata.fetch(:timestamp)).to_date
            )
          )
        end,
        to: [Ordering::OrderConfirmed]
      )
    end

    def enable_three_plus_one_free_process(cqrs)
      ThreePlusOneFree.new(cqrs)
    end
  end
end
