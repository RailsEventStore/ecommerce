require_relative "../../ordering/lib/ordering"
require_relative "../../pricing/lib/pricing"
require_relative "../../product_catalog/lib/product_catalog"
require_relative "../../crm/lib/crm"
require_relative "../../payments/lib/payments"
require_relative "../../inventory/lib/inventory"
require_relative "../../shipping/lib/shipping"
require_relative "../../taxes/lib/taxes"
require_relative "../../invoicing/lib/invoicing"
require_relative 'processes/confirm_order_on_payment_captured'
require_relative 'processes/release_payment_process'
require_relative 'processes/shipment_process'
require_relative 'processes/determine_vat_rates_on_order_submitted'
require_relative 'processes/order_item_invoicing_process'
require_relative 'processes/notify_payments_about_order_value'
require_relative 'processes/sync_shipment_from_ordering'
require_relative 'processes/three_plus_one_free'
require_relative 'processes/reservation_process'

module Processes
  class Configuration
    class << self
      attr_accessor :event_store, :command_bus
    end

    def call(event_store, command_bus)
      self.class.event_store = event_store
      self.class.command_bus = command_bus
      notify_payments_about_order_total_value(event_store, command_bus)
      enable_shipment_sync(event_store, command_bus)
      determine_vat_rates_on_order_submitted(event_store, command_bus)
      set_invoice_payment_date_when_order_confirmed(event_store, command_bus)
      enable_product_name_sync(event_store, command_bus)
      confirm_order_on_payment_captured(event_store, command_bus)

      enable_release_payment_process(event_store, command_bus)
      enable_shipment_process(event_store, command_bus)
      enable_order_item_invoicing_process(event_store, command_bus)
      enable_reservation_process(event_store, command_bus)
      build_pricing_offer_from_ordering_items(event_store, command_bus)
    end

    private

    def enable_shipment_process(event_store, command_bus)
      ShipmentProcess.new(event_store, command_bus)
    end

    def build_pricing_offer_from_ordering_items(event_store, command_bus)
      Infra::Process.new(event_store, command_bus)
                    .call(Ordering::ItemAddedToBasket, [:order_id, :product_id],
                          Pricing::AddPriceItem, [:order_id, :product_id])
      Infra::Process.new(event_store, command_bus)
                    .call(Ordering::ItemRemovedFromBasket, [:order_id, :product_id],
                          Pricing::RemovePriceItem, [:order_id, :product_id])
    end

    def recalculate_pricing_offer_on_order_submitted(event_store, command_bus)
      Infra::Process.new(event_store, command_bus)
                    .call(Ordering::OrderSubmitted, [:order_id],
                          Pricing::CalculateTotalValue, [:order_id])

      Infra::Process.new(event_store, command_bus)
                    .call(Ordering::OrderSubmitted, [:order_id],
                          Pricing::CalculateSubAmounts, [:order_id])
    end

    def enable_shipment_sync(event_store, command_bus)
      SyncShipmentFromOrdering.new(event_store, command_bus)
    end

    def notify_payments_about_order_total_value(event_store, command_bus)
      NotifyPaymentsAboutOrderValue.new(event_store, command_bus)
    end

    def confirm_order_on_payment_captured(event_store, command_bus)
      event_store.subscribe(
        ConfirmOrderOnPaymentCaptured.new(command_bus),
        to: [Payments::PaymentCaptured]
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

    def enable_three_plus_one_free_process(event_store, command_bus)
      ThreePlusOneFree.new(event_store, command_bus)
    end

    def enable_reservation_process(event_store, command_bus)
      event_store.subscribe(
        ReservationProcess,
        to: [
          Ordering::OrderPreSubmitted,
          Ordering::OrderCancelled,
          Ordering::OrderConfirmed
        ]
      )
    end
  end
end
