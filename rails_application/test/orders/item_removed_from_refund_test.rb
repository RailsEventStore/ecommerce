require "test_helper"

module Refunds
  class ItemRemovedFromRefundTest < InMemoryTestCase
    cover "Orders*"

    def test_remove_item_from_refund
      refund_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      another_product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      refundable_products = [{product_id: product_id, quantity: 1}, {product_id: another_product_id, quantity: 1}]
      create_draft_refund(refund_id, order_id, refundable_products)
      prepare_product(product_id, 50)
      prepare_product(another_product_id, 30)
      AddItemToRefund.new.call(item_added_to_refund(refund_id, order_id, product_id))
      AddItemToRefund.new.call(item_added_to_refund(refund_id, order_id, another_product_id))

      RemoveItemFromRefund.new.call(item_removed_from_refund(refund_id, order_id, product_id))

      assert_equal(Refunds::RefundItem.count, 1)
      refund_item = Refunds::RefundItem.find_by(refund_uid: refund_id, product_uid: another_product_id)
      assert_equal(another_product_id, refund_item.product_uid)
      assert_equal(1, refund_item.quantity)
      assert_equal(30, refund_item.price)

      assert_equal(Refunds::Refund.count, 1)
      refund = Refunds::Refund.find_by(uid: refund_id)
      assert_equal(refund.status, "Draft")
    end

    private

    def create_draft_refund(refund_id, order_id, refundable_products)
      draft_refund_created = Ordering::DraftRefundCreated.new(data: { refund_id: refund_id, order_id: order_id, refundable_products: refundable_products })
      CreateDraftRefund.new.call(draft_refund_created)
    end

    def prepare_product(product_id, price)
      run_command(
        ProductCatalog::RegisterProduct.new(
          product_id: product_id,
          )
      )
      run_command(
        ProductCatalog::NameProduct.new(
          product_id: product_id,
          name: "Async Remote"
        )
      )
      run_command(Pricing::SetPrice.new(product_id: product_id, price: price))
    end

    def item_added_to_refund(refund_id, order_id, product_id)
      Ordering::ItemAddedToRefund.new(data: { refund_id: refund_id, order_id: order_id, product_id: product_id })
    end

    def item_removed_from_refund(refund_id, order_id, product_id)
      Ordering::ItemRemovedFromRefund.new(data: { refund_id: refund_id, order_id: order_id, product_id: product_id })
    end
  end
end
