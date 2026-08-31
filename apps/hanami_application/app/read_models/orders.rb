# auto_register: false
# frozen_string_literal: true

module HanamiApplication
  module ReadModels
    class Orders
      Line = Data.define(:product_id, :price, :quantity) do
        def value
          price * quantity
        end
      end

      Order = Data.define(:id, :state, :number, :lines) do
        def total
          lines.values.sum(0, &:value)
        end
      end

      def initialize
        @orders = {}
      end

      def subscribe(event_store)
        event_store.subscribe(method(:draft_order), to: [Pricing::OfferDrafted])
        event_store.subscribe(method(:add_line), to: [Pricing::PriceItemAdded])
        event_store.subscribe(method(:remove_line), to: [Pricing::PriceItemRemoved])
        event_store.subscribe(method(:submit_order), to: [Pricing::OfferAccepted])
        event_store.subscribe(method(:number_order), to: [Fulfillment::OrderRegistered])
        event_store.subscribe(method(:deliver_order), to: [Fulfillment::OrderConfirmed])
      end

      def find(order_id)
        @orders[order_id]
      end

      private

      def draft_order(event)
        order_id = event.data.fetch(:order_id)
        @orders[order_id] = Order.new(id: order_id, state: :draft, number: nil, lines: {})
      end

      def add_line(event)
        product_id = event.data.fetch(:product_id)
        update(event) do |order|
          line = order.lines[product_id] || Line.new(product_id: product_id, price: event.data.fetch(:price), quantity: 0)
          order.with(lines: order.lines.merge(product_id => line.with(quantity: line.quantity + 1)))
        end
      end

      def remove_line(event)
        product_id = event.data.fetch(:product_id)
        update(event) do |order|
          line = order.lines.fetch(product_id)
          lines =
            if line.quantity > 1
              order.lines.merge(product_id => line.with(quantity: line.quantity - 1))
            else
              order.lines.except(product_id)
            end
          order.with(lines: lines)
        end
      end

      def submit_order(event)
        update(event) { |order| order.with(state: :submitted) }
      end

      def number_order(event)
        update(event) { |order| order.with(number: event.data.fetch(:order_number)) }
      end

      def deliver_order(event)
        update(event) { |order| order.with(state: :delivered) }
      end

      def update(event)
        order_id = event.data.fetch(:order_id)
        @orders[order_id] = yield(@orders.fetch(order_id))
      end
    end
  end
end
