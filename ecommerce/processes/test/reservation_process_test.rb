require_relative "test_helper"

module Processes
  class ReservationProcessTest < Test
    cover "Processes::ReservationProcess*"

    def test_reserve_commands_are_dispatched
      process = ReservationProcess.new(event_store, command_bus)
      given([order_pre_submitted]).each { |event| process.call(event) }
      assert_all_commands(
        Inventory::Reserve.new(product_id: product_id, order_id: order_id, quantity: 1),
        Inventory::Reserve.new(product_id: another_product_id, order_id: order_id, quantity: 2)
      )
    end

    def test_accept_order_command_is_dispatched_when_all_stock_is_reserved
      process = ReservationProcess.new(event_store, command_bus)
      given([order_pre_submitted, stock_reserved(product_id), stock_reserved(another_product_id)]).each { |event| process.call(event) }
      assert_command(Ordering::AcceptOrder.new(order_id: order_id))
    end

    def test_reject_order_command_is_dispatched_when_sth_is_unavailable
      process = ReservationProcess.new(event_store, command_bus)
      given([order_pre_submitted, stock_unavailable(product_id)]).each { |event| process.call(event) }
      assert_command(Ordering::RejectOrder.new(order_id: order_id))
    end

    def test_compensation_when_sth_is_unavailable
      process = ReservationProcess.new(event_store, command_bus)
      given([order_pre_submitted, stock_reserved(product_id)]).each { |event| process.call(event) }

      command_bus.clear_all_received

      given([stock_unavailable(another_product_id)]).each { |event| process.call(event) }
      assert_all_commands(
        Ordering::RejectOrder.new(order_id: order_id),
        Inventory::Release.new(product_id: product_id, order_id: order_id, quantity: 1)
      )
    end

    def test_compensation_when_sth_is_unavailable_with_different_events_order
      process = ReservationProcess.new(event_store, command_bus)
      given([order_pre_submitted, stock_unavailable(product_id)]).each { |event| process.call(event) }

      command_bus.clear_all_received

      given([stock_reserved(another_product_id)]).each { |event| process.call(event) }
      assert_all_commands(
        Inventory::Release.new(product_id: another_product_id, order_id: order_id, quantity: 2)
      )
    end

    def test_compensation_on_order_cancelled
      process = ReservationProcess.new(event_store, command_bus)
      given([order_pre_submitted, stock_reserved(product_id), stock_reserved(another_product_id)]).each { |event| process.call(event) }

      command_bus.clear_all_received
      given([order_cancelled]).each { |event| process.call(event) }
      assert_all_commands(
        Inventory::Release.new(product_id: product_id, order_id: order_id, quantity: 1),
        Inventory::Release.new(product_id: another_product_id, order_id: order_id, quantity: 2)
      )
    end

    def test_dispatch_on_order_confirmed
      process = ReservationProcess.new(event_store, command_bus)
      given([order_pre_submitted, stock_reserved(product_id), stock_reserved(another_product_id)]).each { |event| process.call(event) }

      command_bus.clear_all_received

      given([order_confirmed]).each { |event| process.call(event) }
      assert_all_commands(
        Inventory::Dispatch.new(product_id: product_id, quantity: 1),
        Inventory::Dispatch.new(product_id: another_product_id, quantity: 2)
      )
    end

    private

    def product_id
      @product_id ||= SecureRandom.uuid
    end

    def another_product_id
      @another_product_id ||= SecureRandom.uuid
    end

    def order_pre_submitted
      Ordering::OrderPreSubmitted.new(
        data: {
          order_id: order_id,
          order_number: order_number,
          customer_id: customer_id,
          order_lines: { product_id => 1, another_product_id => 2 }
        }
      )
    end

    def order_cancelled
      Ordering::OrderCancelled.new(
        data: {
          order_id: order_id
        }
      )
    end

    def stock_reserved(product_id)
      Inventory::StockReserved.new(
        data: {
          product_id: product_id,
          order_id: order_id,
          quantity: 1
        }
      )
    end

    def stock_unavailable(product_id)
      Inventory::StockUnavailable.new(
        data: {
          product_id: product_id,
          order_id: order_id,
          quantity: 1
        }
      )
    end
  end
end