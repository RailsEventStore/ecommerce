require "test_helper"

module Processes
  class OrderAcceptanceTest < ProcessTest
    cover "Processes::OrderAcceptance*"

    def test_accepts_a_nonempty_order_only_when_requested
      given([item_added, item_added, item_removed], process:)
      assert_no_command

      given([acceptance_requested], process:)

      assert_acceptance(order_id)
    end

    def test_does_not_accept_an_empty_order
      assert_raises(OrderAcceptance::IsEmpty) do
        given([acceptance_requested], process:)
      end

      assert_no_command
    end

    def test_does_not_accept_an_order_after_removing_its_last_item
      given([item_added, item_removed], process:)

      assert_raises(OrderAcceptance::IsEmpty) do
        given([acceptance_requested], process:)
      end

      assert_no_command
    end

    def test_can_request_again_after_filling_an_empty_order
      assert_raises(OrderAcceptance::IsEmpty) do
        given([acceptance_requested], process:)
      end

      given([item_added], process:)
      assert_no_command

      given([acceptance_requested], process:)

      assert_acceptance(order_id)
    end

    def test_edits_after_a_request_do_not_trigger_another_acceptance
      given([item_added, item_added, acceptance_requested], process:)
      command_bus.clear_all_received

      given([item_removed, item_added], process:)

      assert_no_command

      given([acceptance_requested], process:)

      assert_acceptance(order_id)
    end

    def test_keeps_orders_separate
      given([item_added(another_order_id), item_added, item_removed], process:)

      assert_raises(OrderAcceptance::IsEmpty) do
        given([acceptance_requested], process:)
      end
      assert_no_command

      given([acceptance_requested(another_order_id)], process:)

      assert_acceptance(another_order_id)
    end

    private

    def process
      OrderAcceptance.new.with(event_store: event_store, command_bus: command_bus)
    end

    def assert_acceptance(id)
      assert_equal(1, command_bus.all_received.size)
      assert_instance_of(Pricing::AcceptOffer, command_bus.received)
      assert_equal(id, command_bus.received.order_id)
    end

    def another_order_id
      @another_order_id ||= SecureRandom.uuid
    end

    def product_id
      @product_id ||= SecureRandom.uuid
    end

    def item_added(id = order_id)
      Pricing::PriceItemAdded.new(data: { order_id: id, product_id: product_id, price: 20 })
    end

    def item_removed
      Pricing::PriceItemRemoved.new(data: { order_id: order_id, product_id: product_id, price: 20 })
    end

    def acceptance_requested(id = order_id)
      Pricing::OrderAcceptanceRequested.new(data: { order_id: id })
    end
  end
end
