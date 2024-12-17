require "test_helper"

module Refunds
  class ItemRemovedFromRefundTest < InMemoryTestCase
    cover "Orders*"

    def test_removing_items_from_refund
      customer_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      another_product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      refund_id = SecureRandom.uuid
      register_customer(customer_id)
      prepare_product(product_id, 50)
      prepare_product(another_product_id, 30)
      add_item_to_basket(order_id, product_id)
      add_item_to_basket(order_id, another_product_id)
      assign_customer_to_order(customer_id, order_id)
      submit_order(order_id, customer_id)
      confirm_order(order_id)
      create_draft_refund(refund_id, order_id)
      add_item_to_refund(refund_id, order_id, product_id)
      add_item_to_refund(refund_id, order_id, product_id)
      add_item_to_refund(refund_id, order_id, another_product_id)
      remove_item_from_refund(refund_id, order_id, product_id)
      remove_item_from_refund(refund_id, order_id, another_product_id)

      assert_equal(Refunds::RefundItem.count, 1)
      refund_item = Refunds::RefundItem.find_by(refund_uid: refund_id, product_uid: product_id)
      assert_equal(refund_item.product_uid, product_id)
      assert_equal(refund_item.quantity, 1)
      assert_equal(refund_item.price, 50)

      assert_equal(Refunds::Refund.count, 1)
      refund = Refunds::Refund.find_by(uid: refund_id)
      assert_equal(refund.status, "Draft")
    end

    private

    def item_added_to_basket(order_id, product_id)
      event_store.publish(Pricing::PriceItemAdded.new(data: { product_id: product_id, order_id: order_id }))
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

    def register_customer(customer_id)
      run_command(Crm::RegisterCustomer.new(customer_id: customer_id, name: "Arkency"))
    end

    def assign_customer_to_order(customer_id, order_id)
      run_command(Crm::AssignCustomerToOrder.new(customer_id: customer_id, order_id: order_id))
    end

    def add_item_to_basket(order_id, product_id)
      run_command(Ordering::AddItemToBasket.new(order_id: order_id, product_id: product_id))
    end

    def submit_order(order_id, customer_id)
      order_number = Ordering::FakeNumberGenerator::FAKE_NUMBER
      run_command(Ordering::SubmitOrder.new(order_id: order_id, order_number: order_number, customer_id: customer_id))
    end

    def confirm_order(order_id)
      run_command(Fulfillment::ConfirmOrder.new(order_id: order_id))
    end

    def create_draft_refund(refund_id, order_id)
      run_command(Ordering::CreateDraftRefund.new(refund_id: refund_id, order_id: order_id))
    end

    def add_item_to_refund(refund_id, order_id, product_id)
      run_command(Ordering::AddItemToRefund.new(refund_id: refund_id, order_id: order_id, product_id: product_id))
    end

    def remove_item_from_refund(refund_id, order_id, product_id)
      run_command(Ordering::RemoveItemFromRefund.new(refund_id: refund_id, order_id: order_id, product_id: product_id))
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
