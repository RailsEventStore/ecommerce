module Refunds
  class AddItemToRefund
    def call(event)
      refund = Refund.find_by!(uid: event.data.fetch(:refund_id))
      product = Orders::Product.find_by!(uid: event.data.fetch(:product_id))

      item = refund.refund_items.find_or_create_by(product_uid: product.uid) do |item|
        item.price = product.price
        item.quantity = 0
      end

      refund.total_value += item.price
      item.quantity += 1

      ActiveRecord::Base.transaction do
        refund.save!
        item.save!
      end
    end
  end
end
