module Processes
  module StateProjectors
    class OrderItemInvoicingProcess
      ProcessState = Data.define(:order_id, :product_id, :quantity, :vat_rate, :discounted_amount) do
        def initialize(order_id: nil, product_id: nil, quantity: nil, vat_rate: nil, discounted_amount: nil)
          super
        end

        def can_create_invoice_item?
          order_id && product_id && quantity && vat_rate && discounted_amount
        end
      end

      def self.initial_state_instance
        ProcessState.new
      end

      def self.apply(state_instance, event)
        case event
        when Pricing::PriceItemValueCalculated
          state_instance.with(
            order_id: event.data.fetch(:order_id),
            product_id: event.data.fetch(:product_id),
            quantity: event.data.fetch(:quantity),
            discounted_amount: event.data.fetch(:discounted_amount)
          )
        when Taxes::VatRateDetermined
          state_instance.with(
            vat_rate: event.data.fetch(:vat_rate)
          )
        end
      end
    end
  end
end
