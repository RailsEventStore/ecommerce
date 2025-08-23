module Processes
  class InvoiceGeneration
    include Infra::ProcessManager.with_state { Invoice }

    subscribes_to(
      Pricing::PriceItemAdded,
      Pricing::PriceItemRemoved,
      Pricing::PercentageDiscountSet,
      Pricing::PercentageDiscountChanged,
      Pricing::PercentageDiscountRemoved
    )

    def act
    end

    private

    def fetch_id(event)
      event.data.fetch(:order_id)
    end

    def apply(event)
    end

  end

  Invoice = Data.define do
  end

end
