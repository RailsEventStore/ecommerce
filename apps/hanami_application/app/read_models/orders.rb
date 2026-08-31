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

      def initialize(orders, order_lines)
        @orders = orders
        @order_lines = order_lines
      end

      def subscribe(event_store)
        handlers.each { |event_type, handler| event_store.subscribe(handler, to: [event_type]) }
      end

      def find(order_id)
        row = @orders.by_pk(order_id).one
        return unless row

        Order.new(id: row[:id], state: row[:state].to_sym, number: row[:number], lines: lines_for(order_id))
      end

      private

      def handlers
        {
          Pricing::OfferDrafted => method(:draft_order),
          Pricing::PriceItemAdded => method(:add_line),
          Pricing::PriceItemRemoved => method(:remove_line),
          Pricing::OfferAccepted => method(:submit_order),
          Fulfillment::OrderRegistered => method(:number_order),
          Fulfillment::OrderConfirmed => method(:deliver_order)
        }
      end

      def draft_order(event)
        @orders.insert(id: event.data.fetch(:order_id), state: "draft")
      end

      def add_line(event)
        line = line_for(event)
        if (existing = line.one)
          line.update(quantity: existing[:quantity] + 1)
        else
          @order_lines.insert(
            order_id: event.data.fetch(:order_id),
            product_id: event.data.fetch(:product_id),
            price: event.data.fetch(:price),
            quantity: 1
          )
        end
      end

      def remove_line(event)
        line = line_for(event)
        existing = line.one!
        if existing[:quantity] > 1
          line.update(quantity: existing[:quantity] - 1)
        else
          line.delete
        end
      end

      def submit_order(event)
        update_order(event, state: "submitted")
      end

      def number_order(event)
        update_order(event, number: event.data.fetch(:order_number))
      end

      def deliver_order(event)
        update_order(event, state: "delivered")
      end

      def update_order(event, attributes)
        @orders.by_pk(event.data.fetch(:order_id)).update(attributes)
      end

      def line_for(event)
        @order_lines.where(
          order_id: event.data.fetch(:order_id),
          product_id: event.data.fetch(:product_id)
        )
      end

      def lines_for(order_id)
        @order_lines.where(order_id: order_id).to_a.to_h do |row|
          [row[:product_id], Line.new(product_id: row[:product_id], price: row[:price], quantity: row[:quantity])]
        end
      end
    end
  end
end
