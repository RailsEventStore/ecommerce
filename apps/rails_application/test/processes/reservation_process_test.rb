require "test_helper"

module Processes
  class ReservationProcessTest < ProcessTest
    cover "Processes::ReservationProcess*"

    def test_happy_path
      process = ReservationProcess.new.with(event_store: event_store, command_bus: command_bus)

      given([basket_events, offer_accepted], process:)

      assert_equal(3, command_bus.all_received.size)
      assert_inventory_command(0, Inventory::Reserve, product_id, 1)
      assert_inventory_command(1, Inventory::Reserve, another_product_id, 2)
      assert_instance_of(Fulfillment::RegisterOrder, command_bus.all_received.fetch(2))
      assert_equal(order_id, command_bus.all_received.fetch(2).order_id)
      assert_equal(:accepted, process.state.order)
    end

    def test_rejects_order_and_compensates_stock_when_sth_is_unavailable
      process = ReservationProcess.new.with(
        event_store: event_store,
        command_bus: FailingReserveCommandBus.new(command_bus, product_id)
      )

      given([basket_events, offer_accepted], process:)

      assert_equal(4, command_bus.all_received.size)
      assert_inventory_command(0, Inventory::Reserve, product_id, 1)
      assert_inventory_command(1, Inventory::Reserve, another_product_id, 2)
      assert_inventory_command(2, Inventory::Release, another_product_id, 2)
      command = command_bus.all_received.fetch(3)
      assert_instance_of(Pricing::RejectOffer, command)
      assert_equal(order_id, command.order_id)
      assert_equal("Some products were unavailable", command.reason)
      assert_equal([product_id], command.unavailable_product_ids)

      command_bus.clear_all_received
      given([item_removed(product_id), item_removed(another_product_id), offer_accepted], process:)

      assert_equal(2, command_bus.all_received.size)
      assert_inventory_command(0, Inventory::Reserve, another_product_id, 1)
      assert_instance_of(Fulfillment::RegisterOrder, command_bus.all_received.fetch(1))
      assert_equal(order_id, command_bus.all_received.fetch(1).order_id)
    end

    def test_release_stock_when_order_is_cancelled
      process = ReservationProcess.new.with(event_store: event_store, command_bus: command_bus)
      given([basket_events, offer_accepted], process:)
      command_bus.clear_all_received

      given([item_removed(product_id), item_added(another_product_id)], process:)
      assert_no_command
      given([order_cancelled], process:)

      assert_equal(2, command_bus.all_received.size)
      assert_inventory_command(0, Inventory::Release, product_id, 1)
      assert_inventory_command(1, Inventory::Release, another_product_id, 2)

      command_bus.clear_all_received
      given([item_added(product_id)], process:)
      assert_no_command
      assert_equal(:cancelled, process.state.order)
    end

    def test_dispatch_stock_when_order_is_confirmed
      process = ReservationProcess.new.with(event_store: event_store, command_bus: command_bus)
      given([basket_events, offer_accepted], process:)
      command_bus.clear_all_received

      given([item_removed(another_product_id), item_added(product_id)], process:)
      assert_no_command
      given([order_confirmed], process:)

      assert_equal(2, command_bus.all_received.size)
      assert_inventory_command(0, Inventory::Dispatch, product_id, 1)
      assert_inventory_command(1, Inventory::Dispatch, another_product_id, 2)

      command_bus.clear_all_received
      given([item_removed(product_id)], process:)
      assert_no_command
      assert_equal(:confirmed, process.state.order)
    end

    def test_basket_changes_do_not_issue_commands
      given(basket_events, process:)

      assert_no_command
      assert_nil(process.state.order)
    end

    def test_reconstructs_quantities_separately_for_each_order
      given(
        [item_added(product_id), item_added(product_id, another_order_id),
         item_added(product_id, another_order_id), offer_accepted(another_order_id)],
        process:
      )

      assert_equal(2, command_bus.all_received.size)
      assert_inventory_command(0, Inventory::Reserve, product_id, 2)
      assert_instance_of(Fulfillment::RegisterOrder, command_bus.all_received.fetch(1))
      assert_equal(another_order_id, command_bus.all_received.fetch(1).order_id)

      command_bus.clear_all_received
      given([offer_accepted], process:)

      assert_equal(2, command_bus.all_received.size)
      assert_inventory_command(0, Inventory::Reserve, product_id, 1)
      assert_instance_of(Fulfillment::RegisterOrder, command_bus.all_received.fetch(1))
      assert_equal(order_id, command_bus.all_received.fetch(1).order_id)
    end

    private

    def process
      @process ||= ReservationProcess.new.with(event_store: event_store, command_bus: command_bus)
    end

    def basket_events
      [item_added(product_id), item_added(product_id), item_added(another_product_id),
       item_removed(product_id), item_added(another_product_id)]
    end

    def item_added(product, order = order_id)
      Pricing::PriceItemAdded.new(data: { order_id: order, product_id: product, price: 20 })
    end

    def item_removed(product)
      Pricing::PriceItemRemoved.new(data: { order_id: order_id, product_id: product, price: 20 })
    end

    def product_id
      @product_id ||= SecureRandom.uuid
    end

    def another_product_id
      @another_product_id ||= SecureRandom.uuid
    end

    def another_order_id
      @another_order_id ||= SecureRandom.uuid
    end

    def offer_accepted(order = order_id)
      Pricing::OfferAccepted.new(
        data: {
          order_id: order,
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
