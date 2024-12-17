module Refunds
  class CreateDraftRefund
    def call(event)
      Refund.create!(uid: event.data[:refund_id], order_uid: event.data[:order_id], status: "Draft", total_value: 0)
    end
  end
end
