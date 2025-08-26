require "test_helper"

module Refunds
  class ItemAddedToRefundTest < InMemoryTestCase
    cover "Orders*"

    def test_add_item_to_refund
      refund_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      prepare_product(product_id, 50)
      place_order(order_id, product_id, 50)
      create_draft_refund(refund_id, order_id)

      AddItemToRefund.new.call(item_added_to_refund(refund_id, order_id, product_id))

      assert_equal(1, Refunds::RefundItem.count)
      refund_item = Refunds::RefundItem.find_by(refund_uid: refund_id, product_uid: product_id)
      assert_equal(product_id, refund_item.product_uid)
      assert_equal(1, refund_item.quantity)
      assert_equal(50, refund_item.price)

      assert_equal(1, Refunds::Refund.count)
      refund = Refunds::Refund.find_by(uid: refund_id)
      assert_equal("Draft", refund.status)
    end

    private

    def event_store
      Rails.configuration.event_store
    end

    def prepare_product(product_id, price)
      event_store.publish(
        ProductCatalog::ProductRegistered.new(
          data: { product_id: product_id }
        )
      )
      event_store.publish(
        ProductCatalog::ProductNamed.new(
          data: { product_id: product_id, name: "Async Remote" }
        )
      )
      event_store.publish(Pricing::PriceSet.new(data: { product_id: product_id, price: price }))
    end

    def place_order(order_id, product_id, price)
      event_store.publish(
        Pricing::PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            base_price: price,
            price: price,
            base_total_value: price,
            total_value: price
          }
        )
      )
      event_store.publish(
        Pricing::OfferAccepted.new(
          data: {
            order_id: order_id,
            order_lines: [{ product_id: product_id, quantity: 1 }]
          }
        )
      )
    end

    def create_draft_refund(refund_id, order_id)
      draft_refund_created = Ordering::DraftRefundCreated.new(
        data: { refund_id: refund_id, order_id: order_id, refundable_products: [] }
      )
      CreateDraftRefund.new.call(draft_refund_created)
    end

    def item_added_to_refund(refund_id, order_id, product_id)
      Ordering::ItemAddedToRefund.new(data: { refund_id: refund_id, order_id: order_id, product_id: product_id })
    end
  end
end
