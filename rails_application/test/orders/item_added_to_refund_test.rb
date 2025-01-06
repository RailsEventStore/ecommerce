require "test_helper"

module Refunds
  class ItemAddedToRefundTest < InMemoryTestCase
    cover "Orders*"

    def test_add_item_to_refund
      refund_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      prepare_product(product_id, 50)
      create_draft_refund(refund_id, order_id)

      AddItemToRefund.new.call(item_added_to_refund(refund_id, order_id, product_id))

      assert_equal(Refunds::RefundItem.count, 1)
      refund_item = Refunds::RefundItem.find_by(refund_uid: refund_id, product_uid: product_id)
      assert_equal(product_id, refund_item.product_uid)
      assert_equal(1, refund_item.quantity)
      assert_equal(50, refund_item.price)

      assert_equal(Refunds::Refund.count, 1)
      refund = Refunds::Refund.find_by(uid: refund_id)
      assert_equal(refund.status, "Draft")
    end

    private

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

    def create_draft_refund(refund_id, order_id)
      run_command(
        Ordering::CreateDraftRefund.new(refund_id: refund_id, order_id: order_id)
      )
    end

    def item_added_to_refund(refund_id, order_id, product_id)
      Ordering::ItemAddedToRefund.new(data: { refund_id: refund_id, order_id: order_id, product_id: product_id })
    end
  end
end
