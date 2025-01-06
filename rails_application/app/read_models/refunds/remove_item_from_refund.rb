module Refunds
  class RemoveItemFromRefund
    def call(event)
      refund = Refund.find_by!(uid: event.data.fetch(:refund_id))
      item = refund.refund_items.find_by!(product_uid: event.data.fetch(:product_id))

      refund.total_value -= item.price
      item.quantity -= 1

      ActiveRecord::Base.transaction do
        refund.save!
        item.quantity > 0 ? item.save! : item.destroy!
      end
    end
  end
end
