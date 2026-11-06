module Processes
  class OrderAcceptance
    include RubyEventStore::ProcessManager.with_state { ProcessState }

    subscribes_to(
      Pricing::PriceItemAdded,
      Pricing::PriceItemRemoved,
      Pricing::OrderAcceptanceRequested
    )

    private

    def act
      return unless state.acceptance_requested

      if state.item_count.zero?
        command_bus.call(Pricing::RejectEmptyOrderAcceptance.new(id))
      else
        command_bus.call(Pricing::AcceptOffer.new(id))
      end
    end

    def apply(event)
      case event
      when Pricing::PriceItemAdded
        state.with(item_count: state.item_count + 1, acceptance_requested: false)
      when Pricing::PriceItemRemoved
        state.with(item_count: state.item_count - 1, acceptance_requested: false)
      when Pricing::OrderAcceptanceRequested
        state.with(acceptance_requested: true)
      end
    end

    def fetch_id(event)
      event.data.fetch(:order_id)
    end

    ProcessState = Data.define(:item_count, :acceptance_requested) do
      def initialize(item_count: 0, acceptance_requested: false)
        super
      end
    end
  end
end
