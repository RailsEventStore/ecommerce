require "test_helper"

module Processes
  class JoinProcessTest < ProcessTest
    cover "Processes::JoinProcess*"
    cover "Processes::ReleasePaymentOnOrderExpiration*"
    cover "Processes::ShipmentProcess*"

    def test_timeout_is_required_to_be_positive_and_finite
      [0, -1, Float::INFINITY, Float::NAN].each do |seconds|
        assert_raises(ArgumentError) { process.with_timeout(seconds, scheduler) }
      end
    end

    def test_schedules_one_timer_on_an_isolated_process_stream_and_replays_without_effects
      given([order_placed], process: bounded_process)
      assert_equal(1, scheduled.size)
      assert_equal("Processes::ReleasePaymentOnOrderExpiration::Bounded$#{order_id}", scheduled.first.fetch(1))
      assert_equal(90, scheduled.first.fetch(2))
      assert_instance_of(JoinDefinition::TimedOut, scheduled.first.fetch(0))
      assert_equal(order_id, scheduled.first.fetch(0).data.fetch(:order_id))
      assert_equal("Processes::ReleasePaymentOnOrderExpiration", scheduled.first.fetch(0).data.fetch(:process))
      assert_equal([], event_store.read.stream("Processes::ReleasePaymentOnOrderExpiration$#{order_id}").to_a)
      assert_equal(90, event_store.read.stream(scheduled.first.fetch(1)).last.data.fetch(:seconds))
      assert_equal(scheduled.first.fetch(0).event_id, event_store.read.stream(scheduled.first.fetch(1)).last.data.fetch(:timeout_event_id))
      assert_equal(order_id, event_store.read.stream(scheduled.first.fetch(1)).last.data.fetch(:order_id))
      assert_equal(event_store.read.stream(scheduled.first.fetch(1)).last, bounded_process.state.events.fetch(JoinDefinition::TimeoutScheduled))
      given([payment_authorized], process: process.with_timeout(90, scheduler))
      assert_equal(1, scheduled.size)
      bounded_process.replay(event_store.read.stream(scheduled.first.fetch(1)).to_a)
      assert_no_command
      assert_equal(1, scheduled.size)
    end

    def test_delivered_timeout_stops_commands_and_is_persisted_on_the_target_stream
      given([order_placed], process: bounded_process)
      given([scheduled.first.fetch(0), payment_authorized, order_expired], process: bounded_process)
      assert_no_command
      assert_equal(:TimedOut, bounded_process.state.outcome)
      assert_includes(event_store.read.stream(scheduled.first.fetch(1)).to_a.map(&:event_id), scheduled.first.fetch(0).event_id)
    end

    def test_legacy_adapter_keeps_stream_name_and_has_no_deadline_or_terminal_state
      given([order_placed, payment_authorized, order_expired, payment_released, payment_authorized], process: process)
      assert_equal(2, command_bus.all_received.size)
      assert_equal([], scheduled)
      assert_equal(5, event_store.read.stream("Processes::ReleasePaymentOnOrderExpiration$#{order_id}").count)
      assert_equal([], event_store.read.stream("Processes::ReleasePaymentOnOrderExpiration::Bounded$#{order_id}").to_a)
    end

    def test_timeout_for_one_order_does_not_stop_another_order
      given([
        payment_authorized,
        Payments::PaymentAuthorized.new(data: { order_id: other_order_id })
      ], process: bounded_process)
      assert_equal(2, scheduled.size)
      assert_equal([order_id, other_order_id], scheduled.map { |entry| entry.fetch(0).data.fetch(:order_id) })
      refute_equal(scheduled.first.fetch(1), scheduled.last.fetch(1))
      refute_equal(scheduled.first.fetch(0).event_id, scheduled.last.fetch(0).event_id)
      given([
        scheduled.first.fetch(0),
        order_expired,
        Pricing::OfferExpired.new(data: { order_id: other_order_id })
      ], process: bounded_process)
      assert_equal(1, command_bus.all_received.size)
      assert_instance_of(Payments::ReleasePayment, command_bus.received)
      assert_equal(other_order_id, command_bus.received.order_id)
    end

    def test_completion_ignores_a_late_timer_and_reauthorization
      given([order_expired, payment_authorized, payment_released], process: bounded_process)
      assert_equal(1, command_bus.all_received.size)
      assert_instance_of(Payments::ReleasePayment, command_bus.received)
      command_bus.clear_all_received
      given([scheduled.first.fetch(0), payment_authorized], process: bounded_process)
      assert_no_command
      assert_equal(:Completed, bounded_process.state.outcome)
    end

    def test_kill_before_any_wait_does_not_schedule_and_cannot_be_revived
      given([JoinDefinition::Killed.new(data: { order_id: order_id }), order_expired, payment_authorized], process: bounded_process)
      assert_no_command
      assert_equal([], scheduled)
      assert_equal(:Killed, bounded_process.state.outcome)
    end

    def test_shipment_completes_on_authorization_not_submission
      given([order_placed], process: bounded_shipment)
      given([Shipping::ShipmentSubmitted.new(data: { order_id: order_id }), order_confirmed], process: bounded_shipment)
      assert_instance_of(Shipping::AuthorizeShipment, command_bus.received)
      assert_nil(bounded_shipment.state.outcome)
      given([Shipping::ShipmentAuthorized.new(data: { order_id: order_id })], process: bounded_shipment)
      assert_equal(:Completed, bounded_shipment.state.outcome)
      command_bus.clear_all_received
      given([scheduled.first.fetch(0)], process: bounded_shipment)
      assert_no_command
      assert_equal(1, scheduled.size)
    end

    private

    def process
      ReleasePaymentOnOrderExpiration.new.with(event_store: event_store, command_bus: command_bus)
    end

    def bounded_process
      @bounded_process ||= process.with_timeout(90, scheduler)
    end

    def bounded_shipment
      @bounded_shipment ||= ShipmentProcess.new.with(event_store: event_store, command_bus: command_bus).with_timeout(120, scheduler)
    end

    def scheduler
      ->(*args) { scheduled.push(args) }
    end

    def scheduled
      @scheduled ||= []
    end

    def other_order_id
      @other_order_id ||= SecureRandom.uuid
    end
  end
end
