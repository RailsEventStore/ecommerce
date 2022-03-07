require_relative "test_helper"

module Ordering
  class ArchiveOrderTest < Test
    cover "Ordering::OnArchiveOrder*"

    def test_draft_order_can_be_archived
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"
      product_id = SecureRandom.uuid

      arrange(
        AddItemToBasket.new(
          order_id: aggregate_id,
          product_id: product_id
        )
      )

      assert_events(
        stream,
        OrderArchived.new(data: { order_id: aggregate_id })
      ) { act(ArchiveOrder.new(order_id: aggregate_id)) }
    end

    def test_submitted_order_can_be_archived
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"
      product_id = SecureRandom.uuid
      customer_id = SecureRandom.uuid

      arrange(
        AddItemToBasket.new(
          order_id: aggregate_id,
          product_id: product_id
        ),
        SubmitOrder.new(
          order_id: aggregate_id,
          order_number: "2018/12/1",
          customer_id: customer_id
        )
      )

      assert_events(
        stream,
        OrderArchived.new(data: { order_id: aggregate_id })
      ) { act(ArchiveOrder.new(order_id: aggregate_id)) }
    end

    def test_paid_order_can_be_archived
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"
      product_id = SecureRandom.uuid
      customer_id = SecureRandom.uuid

      arrange(
        AddItemToBasket.new(
          order_id: aggregate_id,
          product_id: product_id
        ),
        SubmitOrder.new(
          order_id: aggregate_id,
          order_number: "2018/12/1",
          customer_id: customer_id
        ),
        MarkOrderAsPaid.new(order_id: aggregate_id)
      )

      assert_events(
        stream,
        OrderArchived.new(data: { order_id: aggregate_id })
      ) { act(ArchiveOrder.new(order_id: aggregate_id)) }
    end

    def test_expired_order_can_be_archived
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"
      product_id = SecureRandom.uuid
      customer_id = SecureRandom.uuid

      arrange(
        AddItemToBasket.new(
          order_id: aggregate_id,
          product_id: product_id
        ),
        SubmitOrder.new(
          order_id: aggregate_id,
          order_number: "2018/12/1",
          customer_id: customer_id
        ),
        SetOrderAsExpired.new(order_id: aggregate_id)
      )

      assert_events(
        stream,
        OrderArchived.new(data: { order_id: aggregate_id })
      ) { act(ArchiveOrder.new(order_id: aggregate_id)) }
    end
  end
end
