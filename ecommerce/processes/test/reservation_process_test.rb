require_relative "test_helper"

module Processes
  class ReservationProcessTest < Test
    cover "Processes::ReservationProcess*"

    def test_happy_path
      process = ReservationProcess.new
      given([order_pre_submitted]).each { |event| process.call(event) }
      assert_all_commands(
        Inventory::Reserve.new(product_id: product_id, quantity: 1),
        Inventory::Reserve.new(product_id: another_product_id, quantity: 2),
        Ordering::AcceptOrder.new(order_id: order_id)
      )
    end

    class EnhancedFakeCommandBus < SimpleDelegator
      def initialize(command_bus, command_error_hash = {})
        super(command_bus)
        @command_error_hash = command_error_hash
      end

      def call(command)
        super(command)
        raise @command_error_hash[command] if @command_error_hash[command]
      end
    end

    def test_reject_order_command_is_dispatched_when_sth_is_unavailable
      failing_command = Inventory::Reserve.new(product_id: product_id, quantity: 1)
      enhanced_command_bus = EnhancedFakeCommandBus.new(command_bus, failing_command => Inventory::InventoryEntry::InventoryNotAvailable)
      process = ReservationProcess.new
      process.command_bus = enhanced_command_bus
      given([order_pre_submitted]).each { |event| process.call(event) }
      assert_all_commands(
        failing_command,
        Ordering::RejectOrder.new(order_id: order_id)
      )
    end

    def test_compensation_when_sth_is_unavailable
      failing_command = Inventory::Reserve.new(product_id: another_product_id, quantity: 2)
      enhanced_command_bus = EnhancedFakeCommandBus.new(command_bus, failing_command => Inventory::InventoryEntry::InventoryNotAvailable)
      process = ReservationProcess.new
      process.command_bus = enhanced_command_bus
      given([order_pre_submitted]).each { |event| process.call(event) }
      assert_all_commands(
        Inventory::Reserve.new(product_id: product_id, quantity: 1),
        failing_command,
        Inventory::Release.new(product_id: product_id, quantity: 1),
        Ordering::RejectOrder.new(order_id: order_id)
      )
    end

    def test_release_stock_when_order_is_cancelled
      process = ReservationProcess.new
      given([order_pre_submitted]).each { |event| process.call(event) }

      command_bus.clear_all_received
      given([order_cancelled]).each { |event| process.call(event) }
      assert_all_commands(
        Inventory::Release.new(product_id: product_id, quantity: 1),
        Inventory::Release.new(product_id: another_product_id, quantity: 2)
      )
    end

    def test_dispatch_stock_when_order_is_confirmed
      process = ReservationProcess.new
      given([order_pre_submitted]).each { |event| process.call(event) }

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
  end
end