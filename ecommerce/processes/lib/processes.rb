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
    def call(cqrs)
      enable_pricing_sync_from_ordering(cqrs)
      notify_payments_about_order_total_value(cqrs)
      enable_inventory_sync_from_ordering(cqrs)
      enable_shipment_sync(cqrs)
      check_product_availability_on_adding_item_to_basket(cqrs)
      determine_vat_rates_on_order_submitted(cqrs)
      set_invoice_payment_date_when_order_confirmed(cqrs)
      enable_product_name_sync(cqrs)

      enable_release_payment_process(cqrs)
      enable_order_confirmation_process(cqrs)
      enable_shipment_process(cqrs)
      enable_order_item_invoicing_process(cqrs)
    end

    private

    def enable_shipment_process(cqrs)
      ShipmentProcess.new(cqrs)
    end

    def enable_shipment_sync(cqrs)
      SyncShipmentFromOrdering.new(cqrs)
    end

    def notify_payments_about_order_total_value(cqrs)
      NotifyPaymentsAboutOrderValue.new(cqrs)
    end

    def enable_inventory_sync_from_ordering(cqrs)
      SyncInventoryFromOrdering.new(cqrs)
    end

    def enable_pricing_sync_from_ordering(cqrs)
      SyncPricingFromOrdering.new(cqrs)
    end

    def enable_order_confirmation_process(cqrs)
      cqrs.subscribe(
        OrderConfirmation.new(cqrs),
        [Payments::PaymentAuthorized, Payments::PaymentCaptured]
      )
    end

    def enable_release_payment_process(cqrs)
      cqrs.subscribe(
        ReleasePaymentProcess.new(cqrs),
        [
          Ordering::OrderSubmitted,
          Ordering::OrderExpired,
          Ordering::OrderConfirmed,
          Payments::PaymentAuthorized,
          Payments::PaymentReleased
        ]
      )
    end

    def enable_order_item_invoicing_process(cqrs)
      cqrs.subscribe(
        OrderItemInvoicingProcess.new(cqrs),
        [
          Pricing::PriceItemValueCalculated,
          Taxes::VatRateDetermined
        ]
      )
    end

    def check_product_availability_on_adding_item_to_basket(cqrs)
      cqrs.subscribe(
        CheckAvailabilityOnOrderItemAddedToBasket.new(cqrs),
        [Ordering::ItemAddedToBasket]
      )
    end

    def determine_vat_rates_on_order_submitted(cqrs)
      cqrs.subscribe(
        DetermineVatRatesOnOrderSubmitted.new(cqrs),
        [Ordering::OrderSubmitted]
      )
    end

    def enable_product_name_sync(cqrs)
      cqrs.process(
           ProductCatalog::ProductNamed,                [:product_id, :name],
           Invoicing::SetProductNameDisplayedOnInvoice, [:product_id, :name_displayed])
    end


    def set_invoice_payment_date_when_order_confirmed(cqrs)
      cqrs.subscribe(
        ->(event) do
          cqrs.run(
            Invoicing::SetPaymentDate.new(
              invoice_id: event.data.fetch(:order_id),
              payment_date: Time.zone.at(event.metadata.fetch(:timestamp)).to_date
            )
          )
        end,
        [Ordering::OrderConfirmed]
      )
    end

    def enable_three_plus_one_free_process(cqrs)
      ThreePlusOneFree.new(cqrs)
    end
  end
end
