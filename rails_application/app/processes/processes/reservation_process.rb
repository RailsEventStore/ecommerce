module Processes
  class ReservationProcess
    include Infra::ProcessManager.with_state { ProcessState }

    subscribes_to(
      Pricing::OfferAccepted,
      Fulfillment::OrderCancelled,
      Fulfillment::OrderConfirmed
    )

    private

    def act
      case state
      in order: :accepted
        unavailable = reserve_stock
        if unavailable.any?
          reject_order(unavailable)
        else
          accept_order
        end
      in order: :cancelled
        release_stock(state.reserved_product_ids)
      in order: :confirmed
        dispatch_stock
      else
      end
    end

    def apply(event)
      case event
      when Pricing::OfferAccepted
        state.with(
          order: :accepted,
          order_lines: event.data.fetch(:order_lines).map { |ol| [ol.fetch(:product_id), ol.fetch(:quantity)] }.to_h
        )
      when Fulfillment::OrderCancelled
        state.with(order: :cancelled)
      when Fulfillment::OrderConfirmed
        state.with(order: :confirmed)
      end
    end

    def reserve_stock
      unavailable_products = []
      reserved_products = []
      state.order_lines.each do |product_id, quantity|
        command_bus.(Inventory::Reserve.new(product_id: product_id, quantity: quantity))
        reserved_products << product_id
      rescue Inventory::InventoryEntry::InventoryNotAvailable
        unavailable_products << product_id
      end

      if unavailable_products.any?
        release_stock(reserved_products)
      end
      unavailable_products
    end

    def release_stock(product_ids)
      state.order_lines.slice(*product_ids).each do |product_id, quantity|
        command_bus.(Inventory::Release.new(product_id: product_id, quantity: quantity))
      end
    end

    def dispatch_stock
      state.order_lines.each do |product_id, quantity|
        command_bus.(Inventory::Dispatch.new(product_id: product_id, quantity: quantity))
      end
    end

    def accept_order
      command_bus.(Fulfillment::RegisterOrder.new(order_id: id))
    end

    def reject_order(unavailable_product_ids)
      command_bus.(Pricing::RejectOffer.new(
        order_id: id, reason: "Some products were unavailable", unavailable_product_ids:)
      )
    end

    def fetch_id(event)
      event.data.fetch(:order_id)
    end

    ProcessState = Data.define(:order, :order_lines) do
      def initialize(order: nil, order_lines: [])
        super(order:, order_lines: order_lines.freeze)
      end

      def reserved_product_ids = order_lines.keys
    end

  end
end
