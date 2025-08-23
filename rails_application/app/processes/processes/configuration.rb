module Processes
  class Configuration
    class << self
      attr_accessor :event_store, :command_bus
    end

    def call(event_store, command_bus)
      self.class.event_store = event_store
      self.class.command_bus = command_bus
      enable_coupon_discount_process(event_store, command_bus)
      notify_payments_about_order_total_value(event_store, command_bus)
      enable_shipment_sync(event_store, command_bus)
      determine_vat_rates_on_order_placed(event_store, command_bus)
      set_invoice_payment_date_when_order_confirmed(event_store, command_bus)
      enable_product_name_sync(event_store, command_bus)
      confirm_order_on_payment_captured(event_store, command_bus)

      enable_release_payment_process(event_store, command_bus)
      enable_shipment_process(event_store, command_bus)
      enable_order_item_invoicing_process(event_store, command_bus)
      enable_reservation_process(event_store, command_bus)
      enable_welcome_message_process(event_store, command_bus)
      enable_total_order_value_process(event_store, command_bus)
      enable_invoice_generation_process(event_store, command_bus)
    end

    private

    def enable_shipment_process(event_store, command_bus)
      event_store.subscribe(
        ShipmentProcess.new(event_store, command_bus),
        to: ShipmentProcess.subscribed_events
      )
    end

    def enable_shipment_sync(event_store, command_bus)
      SyncShipmentFromPricing.new(event_store, command_bus)
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
          Pricing::OfferExpired,
          Fulfillment::OrderRegistered,
          Fulfillment::OrderConfirmed,
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

    def determine_vat_rates_on_order_placed(event_store, command_bus)
      event_store.subscribe(
        DetermineVatRatesOnOrderPlaced.new(event_store, command_bus),
        to: [
          Pricing::OfferAccepted,
          Fulfillment::OrderRegistered
        ]
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
        to: [Fulfillment::OrderConfirmed]
      )
    end

    def enable_three_plus_one_free_process(event_store, command_bus)
      event_store.subscribe(
        ThreePlusOneFree.new(event_store, command_bus),
        to: ThreePlusOneFree.subscribed_events
      )
    end

    def enable_reservation_process(event_store, command_bus)
      event_store.subscribe(
        ReservationProcess.new(event_store, command_bus),
        to: ReservationProcess.subscribed_events
      )
    end

    def enable_coupon_discount_process(event_store, command_bus)
      Infra::Process.new(event_store, command_bus)
                    .call(Pricing::CouponUsed, [:order_id, :discount],
                          Pricing::SetPercentageDiscount, [:order_id, :amount])
    end

    def enable_welcome_message_process(event_store, command_bus)
      event_store.subscribe(
        WelcomeMessageProcess.new(event_store, command_bus),
        to: [Crm::CustomerRegistered]
      )
    end

    def enable_total_order_value_process(event_store, command_bus)
      event_store.subscribe(
        TotalOrderValue.new(event_store, command_bus),
        to: TotalOrderValue.subscribed_events
      )
    end

    def enable_invoice_generation_process(event_store, command_bus)
      event_store.subscribe(
        InvoiceGeneration.new(event_store, command_bus),
        to: InvoiceGeneration.subscribed_events
      )
    end
  end
end
