require "minitest/autorun"
require "mutant/minitest/coverage"
require "infra"

require_relative "../lib/processes"

module Processes
  class Test < Minitest::Test
    include Infra::TestPlumbing.with(
      event_store: -> { Infra::EventStore.in_memory },
      command_bus: -> { FakeCommandBus.new }
    )

    def before_setup
      super
      Configuration.new.call(cqrs)
    end

    def assert_command(command)
      assert_equal(@command_bus.received, command)
    end

    def assert_no_command
      assert_nil(@command_bus.received)
    end

    private

    class FakeCommandBus
      attr_reader :received

      def call(command)
        @received = command
      end
    end

    def order_id
      @order_id ||= SecureRandom.uuid
    end

    def order_number
      "2018/12/16"
    end

    def customer_id
      @customer_id ||= SecureRandom.uuid
    end

    def given(events, store: cqrs.event_store)
      events.each { |ev| store.append(ev) }
      events
    end

    def order_submitted
      Ordering::OrderSubmitted.new(
        data: {
          order_id: order_id,
          order_number: order_number,
          customer_id: customer_id
        }
      )
    end

    def order_expired
      Ordering::OrderExpired.new(data: { order_id: order_id })
    end

    def order_confirmed
      Ordering::OrderConfirmed.new(data: { order_id: order_id })
    end

    def payment_authorized
      Payments::PaymentAuthorized.new(data: { order_id: order_id })
    end

    def payment_captured
      Payments::PaymentCaptured.new(data: { order_id: order_id })
    end

    def payment_released
      Payments::PaymentReleased.new(data: { order_id: order_id })
    end
  end
end
