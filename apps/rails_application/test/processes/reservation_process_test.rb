require "test_helper"

module Processes
  class ReservationProcessTest < ProcessTest
    cover "Processes::ReservationProcess*"

    def test_happy_path
      process = ReservationProcess.new.with(event_store: event_store, command_bus: command_bus)

      given([offer_accepted], process:)

      assert_equal(3, command_bus.all_received.size)
      assert_inventory_command(0, Inventory::Reserve, product_id, 1)
      assert_inventory_command(1, Inventory::Reserve, another_product_id, 2)
      assert_equal(Fulfillment::RegisterOrder.new(order_id: order_id), command_bus.all_received.fetch(2))
    end

    def test_rejects_order_and_compensates_stock_when_sth_is_unavailable
      process = ReservationProcess.new.with(
        event_store: event_store,
        command_bus: FailingReserveCommandBus.new(command_bus, product_id)
      )

      given([offer_accepted], process:)

      assert_equal(4, command_bus.all_received.size)
      assert_inventory_command(0, Inventory::Reserve, product_id, 1)
      assert_inventory_command(1, Inventory::Reserve, another_product_id, 2)
      assert_inventory_command(2, Inventory::Release, another_product_id, 2)
      assert_equal(
        Pricing::RejectOffer.new(order_id: order_id, reason: "Some products were unavailable", unavailable_product_ids: [product_id]),
        command_bus.all_received.fetch(3)
      )
    end

    def test_release_stock_when_order_is_cancelled
      process = ReservationProcess.new.with(event_store: event_store, command_bus: command_bus)
      given([offer_accepted], process:)
      command_bus.clear_all_received

      given([order_cancelled], process:)

      assert_equal(2, command_bus.all_received.size)
      assert_inventory_command(0, Inventory::Release, product_id, 1)
      assert_inventory_command(1, Inventory::Release, another_product_id, 2)
    end

    def test_dispatch_stock_when_order_is_confirmed
      process = ReservationProcess.new.with(event_store: event_store, command_bus: command_bus)
      given([offer_accepted], process:)
      command_bus.clear_all_received

      given([order_confirmed], process:)

      assert_equal(2, command_bus.all_received.size)
      assert_inventory_command(0, Inventory::Dispatch, product_id, 1)
      assert_inventory_command(1, Inventory::Dispatch, another_product_id, 2)
    end

    private

    def product_id
      @product_id ||= SecureRandom.uuid
    end

    def another_product_id
      @another_product_id ||= SecureRandom.uuid
    end

    def offer_accepted
      Pricing::OfferAccepted.new(
        data: {
          order_id: order_id,
          order_lines: [
            { product_id: product_id, quantity: 1 },
            { product_id: another_product_id, quantity: 2 },
          ]
        }
      )
    end

    def order_cancelled
      Fulfillment::OrderCancelled.new(
        data: {
          order_id: order_id
        }
      )
    end

    def assert_inventory_command(index, command_class, product_id, quantity)
      assert_instance_of(command_class, command_bus.all_received.fetch(index))
      assert_equal(product_id, command_bus.all_received.fetch(index).product_id)
      assert_equal(quantity, command_bus.all_received.fetch(index).quantity)
    end

    class FailingReserveCommandBus < SimpleDelegator
      def initialize(command_bus, product_id)
        super(command_bus)
        @product_id = product_id
      end

      def call(command)
        super(command)
        if command.instance_of?(Inventory::Reserve) && command.product_id == @product_id
          raise Inventory::InventoryEntry::InventoryNotAvailable
        end
      end
    end
  end
end
