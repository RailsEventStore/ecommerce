module Refunds
  class Refund < ApplicationRecord
    self.table_name = "refunds"

    has_many :refund_items,
             class_name: "Refunds::RefundItem",
             foreign_key: :order_uid,
             primary_key: :uid
  end

  class RefundItem < ApplicationRecord
    self.table_name = "refund_items"
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(CreateDraftRefund.new, to: [Ordering::DraftRefundCreated])
    end
  end
end
