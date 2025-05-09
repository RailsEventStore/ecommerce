require_relative 'state_projectors/determine_vat_rates_on_order_placed'

module Processes
  class DetermineVatRatesOnOrderPlaced
    include Infra::ProcessManager.with_state(StateProjectors::DetermineVatRatesOnOrderPlaced)

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

    def fetch_id(event)
      event.data.fetch(:order_id)
    end
  end
end
