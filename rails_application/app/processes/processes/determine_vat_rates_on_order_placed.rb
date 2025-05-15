module Processes
  class DetermineVatRatesOnOrderPlaced
    include Infra::ProcessManager.with_state { ProcessState }

    subscribes_to(
      Pricing::OfferAccepted,
      Fulfillment::OrderRegistered
    )

    private

    def act
      determine_vat_rates if state.placed?
    end

    def determine_vat_rates
      state.order_lines.each do |line|
        product_id = line.fetch(:product_id)
        command = Taxes::DetermineVatRate.new(order_id: state.order_id, product_id: product_id)
        command_bus.call(command)
      end
    end

    def apply(event)
      case event
      when Pricing::OfferAccepted
        state.with(
          offer_accepted: true,
          order_lines: event.data.fetch(:order_lines),
          order_id: event.data.fetch(:order_id)
        )
      when Fulfillment::OrderRegistered
        state.with(order_placed: true)
      end
    end

    def fetch_id(event)
      event.data.fetch(:order_id)
    end

    ProcessState = Data.define(:offer_accepted, :order_placed, :order_id, :order_lines) do
      def initialize(offer_accepted: false, order_placed: false, order_id: nil, order_lines: [])
        super
      end

      def placed? = offer_accepted && order_placed
    end
  end
end
