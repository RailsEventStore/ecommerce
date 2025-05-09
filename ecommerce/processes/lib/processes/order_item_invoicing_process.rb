require_relative 'state_projectors/order_item_invoicing_process'

module Processes
  class OrderItemInvoicingProcess
    include Infra::ProcessManager.with_state(StateProjectors::OrderItemInvoicingProcess)

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
end
