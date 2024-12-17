module Refunds
  class AddItemToRefund
    def call(event)
      refund_id = event.data.fetch(:refund_id)
      Refund.find_or_create_by!(uid: refund_id)
      product_id = event.data.fetch(:product_id)
      item =
        find(refund_id, product_id) ||
          create(refund_id, product_id)
      item.quantity += 1
      item.save!
    end

    private

    def event_store
      Rails.configuration.event_store
    end

    def find(refund_id, product_id)
      Refund
        .find_by_uid(refund_id)
        .refund_items
        .where(product_uid: product_id)
        .first
    end

    def create(refund_id, product_id)
      product = Orders::Product.find_by_uid(product_id)
      Refund
        .find_by(uid: refund_id)
        .refund_items
        .create(
          product_uid: product_id,
          price: product.price,
          quantity: 0
        )
    end
  end
end
