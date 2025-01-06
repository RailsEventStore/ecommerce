module Refunds
  class Refund < ApplicationRecord
    self.table_name = "refunds"

    has_many :refund_items,
             class_name: "Refunds::RefundItem",
             foreign_key: :refund_uid,
             primary_key: :uid
  end

  class RefundItem < ApplicationRecord
    self.table_name = "refund_items"

    attr_accessor :order_line
    delegate :product_name, to: :order_line

    def max_quantity?
      quantity == order_quantity
    end

    def order_quantity
      order_line.quantity
    end

    def value
      quantity * price
    end
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(CreateDraftRefund.new, to: [Ordering::DraftRefundCreated])
      event_store.subscribe(AddItemToRefund.new, to: [Ordering::ItemAddedToRefund])
      event_store.subscribe(RemoveItemFromRefund.new, to: [Ordering::ItemRemovedFromRefund])
    end
  end
end
