module Processes
  class ReservationProcess
    include RubyEventStore::ProcessManager.with_state { ProcessState }

    subscribes_to(
      Pricing::PriceItemAdded,
      Pricing::PriceItemRemoved,
      Pricing::OfferAccepted,
      Fulfillment::OrderCancelled,
      Fulfillment::OrderConfirmed
    )

    private

    def act
      case state
      in action: :reserve
        unavailable = reserve_stock
        if unavailable.any?
          reject_order(unavailable)
        else
          accept_order
        end
      in action: :release
        release_stock(state.reserved_product_ids)
      in action: :dispatch
        dispatch_stock
      in action: nil
      end
    end

    def apply(event)
      case event
      when Pricing::PriceItemAdded
        state.add_item(event.data.fetch(:product_id))
      when Pricing::PriceItemRemoved
        state.remove_item(event.data.fetch(:product_id))
      when Pricing::OfferAccepted
        state.with(order: :accepted, action: :reserve, accepted_order_lines: state.order_lines)
      when Fulfillment::OrderCancelled
        state.with(order: :cancelled, action: :release)
      when Fulfillment::OrderConfirmed
        state.with(order: :confirmed, action: :dispatch)
      end
    end

    def reserve_stock
      unavailable_products = []
      reserved_products = []
      state.accepted_order_lines.each do |product_id, quantity|
        command_bus.(Inventory::Reserve.new(product_id, quantity))
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
      state.accepted_order_lines.slice(*product_ids).each do |product_id, quantity|
        command_bus.(Inventory::Release.new(product_id, quantity))
      end
    end

    def dispatch_stock
      state.accepted_order_lines.each do |product_id, quantity|
        command_bus.(Inventory::Dispatch.new(product_id, quantity))
      end
    end

    def accept_order
      command_bus.(Fulfillment::RegisterOrder.new(id))
    end

    def reject_order(unavailable_product_ids)
      command_bus.(Pricing::RejectOffer.new(
        id, "Some products were unavailable", unavailable_product_ids)
      )
    end

    def fetch_id(event)
      event.data.fetch(:order_id)
    end

    ProcessState = Data.define(:order, :action, :order_lines, :accepted_order_lines) do
      def initialize(order: nil, action: nil, order_lines: {}, accepted_order_lines: {})
        super(order:, action:, order_lines: order_lines.freeze, accepted_order_lines: accepted_order_lines.freeze)
      end

      def add_item(product_id)
        with(action: nil, order_lines: order_lines.merge(product_id => order_lines.fetch(product_id, 0) + 1))
      end

      def remove_item(product_id)
        with(
          action: nil,
          order_lines: order_lines.merge(product_id => order_lines.fetch(product_id) - 1).reject { |_, quantity| quantity.zero? }
        )
      end

      def reserved_product_ids = accepted_order_lines.keys
    end

  end
end
