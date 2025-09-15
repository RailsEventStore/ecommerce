require_relative "test_helper"

module Fulfillment
  class ArchiveOrderTest < Test
    cover "Fulfillment::OnArchiveOrder*"

    def test_order_can_be_archived
      aggregate_id = SecureRandom.uuid
      stream = "Fulfillment::Order$#{aggregate_id}"

      arrange(
        RegisterOrder.new(order_id: aggregate_id)
      )

      assert_events(
        stream,
        OrderArchived.new(data: { order_id: aggregate_id })
      ) { act(ArchiveOrder.new(order_id: aggregate_id)) }
    end

    def test_not_registered_order_can_be_archived
      aggregate_id = SecureRandom.uuid
      stream = "Fulfillment::Order$#{aggregate_id}"

      assert_events(
        stream,
        OrderArchived.new(data: { order_id: aggregate_id })
      ) { act(ArchiveOrder.new(order_id: aggregate_id)) }
    end

    def test_confirmed_order_can_be_archived
      aggregate_id = SecureRandom.uuid
      stream = "Fulfillment::Order$#{aggregate_id}"

      arrange(
        RegisterOrder.new(order_id: aggregate_id),
        ConfirmOrder.new(order_id: aggregate_id)
      )

      assert_events(
        stream,
        OrderArchived.new(data: { order_id: aggregate_id })
      ) { act(ArchiveOrder.new(order_id: aggregate_id)) }
    end
  end
end