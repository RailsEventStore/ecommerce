module Processes
  class OrderItemInvoicingProcess
    include Infra::ProcessManager.with_state { StateProjector }
    subscribes_to(
      Pricing::PriceItemValueCalculated,
      Taxes::VatRateDetermined
    )

    private

    def act
      return unless state.can_create_invoice_item?

      unit_prices = MoneySplitter.new(state.discounted_amount, state.quantity).call
      unit_prices.tally.each do |unit_price, quantity|
        command_bus.call(
          Invoicing::AddInvoiceItem.new(
            invoice_id: state.order_id,
            product_id: state.product_id,
            vat_rate: state.vat_rate,
            quantity: quantity,
            unit_price: unit_price
          )
        )
      end
    end

    def fetch_id(event)
      "#{event.data.fetch(:order_id)}$#{event.data.fetch(:product_id)}"
    end
  end

  class MoneySplitter
    def initialize(amount, quantity)
      @amount = amount
      @weights = Array.new(quantity, 1)
    end

    def call
      distributed_amounts = []
      total_weight = @weights.sum.to_d
      @weights.each do |weight|
        if total_weight.eql?(0)
          distributed_amounts << 0
          next
        end

        p = weight / total_weight
        distributed_amount = (p * @amount).round(2)
        distributed_amounts << distributed_amount
        total_weight -= weight
        @amount -= distributed_amount
      end

      distributed_amounts
    end
  end

  class StateProjector
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
