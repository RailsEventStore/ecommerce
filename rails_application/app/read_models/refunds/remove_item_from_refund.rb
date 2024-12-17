module Refunds
  class RemoveItemFromRefund
    def call(event)
      refund_id = event.data.fetch(:refund_id)
      product_id = event.data.fetch(:product_id)
      item = find(refund_id, product_id)
      item.quantity -= 1
      item.quantity > 0 ? item.save! : item.destroy!
    end

    private
    def find(order_uid, product_id)
      Refund
        .find_by_uid(order_uid)
        .refund_items
        .where(product_uid: product_id)
        .first
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
