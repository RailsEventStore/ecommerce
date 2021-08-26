require 'test_helper'

module Inventory
  class InventoryTest < Ecommerce::InMemoryRESIntegrationTestCase
    include TestPlumbing

    cover 'Inventory*'

    test 'if_stock_level_changes_with_supply_command' do
      product_id = SecureRandom.uuid
      assert_events(inventory_entry_stream(product_id),
                    StockLevelChanged.new(data: { product_id: product_id, quantity: 1, stock_level: 1 })) do
        act(supply(product_id, 1))
      end
    end

    def test_if_reservation_adjusts_on_item_added_to_and_removed_from_basket
      product_id = SecureRandom.uuid
      arrange(
        register_product(product_id),
        set_price(product_id)
      )
      order_id = SecureRandom.uuid
      assert_events(reservation_stream(order_id), ReservationAdjusted.new(data: { order_id: order_id, product_id: product_id, quantity: 1 })) do
        act(add_item(order_id, product_id))
      end
      assert_events(reservation_stream(order_id), ReservationAdjusted.new(data: { order_id: order_id, product_id: product_id, quantity: -1 })) do
        act(remove_item(order_id, product_id))
      end
    end

    def test_if_stock_gets_reserved_on_reservation_submission
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      customer_id = SecureRandom.uuid

      arrange(
        register_product(product_id),
        set_price(product_id),
        supply(product_id, 1),
        register_customer(customer_id),
        add_item(order_id, product_id)
      )

      assert_events(reservation_stream(order_id), ReservationSubmitted.new(data: { order_id: order_id, reservation_items: [product_id: product_id, quantity: 1] })) do
        assert_events(inventory_entry_stream(product_id), StockReserved.new(data: { product_id: product_id, quantity: 1 })) do
          act(submit_order(order_id, customer_id))
        end
      end
    end

    def test_if_stock_gets_released_on_reservation_cancelation
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      customer_id = SecureRandom.uuid

      arrange(
        register_product(product_id),
        set_price(product_id),
        supply(product_id, 1),
        add_item(order_id, product_id),
        register_customer(customer_id),
        submit_order(order_id, customer_id)

      )

      assert_events(reservation_stream(order_id), ReservationCanceled.new(data: { order_id: order_id, reservation_items: [product_id: product_id, quantity: 1] })) do
        assert_events(inventory_entry_stream(product_id), StockReleased.new(data: { product_id: product_id, quantity: 1 })) do
          act(cancel_order(order_id))
        end
      end
    end

    def test_if_stock_level_changes_on_reservation_completion
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      customer_id = SecureRandom.uuid

      arrange(
        register_product(product_id),
        set_price(product_id),
        supply(product_id, 1),
        add_item(order_id, product_id),
        register_customer(customer_id),
        submit_order(order_id, customer_id)
      )

      assert_events(reservation_stream(order_id),
                    ReservationCompleted.new(data: { order_id: order_id, reservation_items: [product_id: product_id, quantity: 1] })) do
        assert_events(inventory_entry_stream(product_id),
                      StockReleased.new(data: { product_id: product_id, quantity: 1 }),
                      StockLevelChanged.new(data: { product_id: product_id, quantity: -1, stock_level: 0 })) do
          act(confirm_order(order_id))
        end
      end

    end

    def test_if_prevents_from_order_submission_when_out_of_stock
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      customer_id = SecureRandom.uuid

      arrange(
        register_product(product_id),
        set_price(product_id),
        supply(product_id, 1),
        add_item(order_id, product_id),
        add_item(order_id, product_id),
        register_customer(customer_id)
      )

      assert_raises(Inventory::InventoryEntry::InventoryNotAvailable) do
        act(submit_order(order_id, customer_id))
      end
    end

    def test_if_prevents_from_order_submission_when_stock_reserved
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      customer_id = SecureRandom.uuid
      another_order_id = SecureRandom.uuid

      arrange(
        register_product(product_id),
        set_price(product_id),
        supply(product_id, 1),
        add_item(order_id, product_id),
        register_customer(customer_id),
        submit_order(order_id, customer_id),
        add_item(another_order_id, product_id)
      )

      assert_raises(Inventory::InventoryEntry::InventoryNotAvailable) do
        act(submit_order(another_order_id, customer_id))
      end
    end

    def test_unless_prevents_from_order_submission_when_stock_level_is_undefined
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      customer_id = SecureRandom.uuid

      arrange(
        register_product(product_id),
        set_price(product_id),
        add_item(order_id, product_id),
        register_customer(customer_id)
      )

      assert_nothing_raised do
        assert_events(inventory_entry_stream(product_id)) do
          act(submit_order(order_id, customer_id))
        end
      end
    end

    private

    def order_stream order_id
      "Ordering::Order$#{order_id}"
    end

    def inventory_entry_stream product_id
      "Inventory::InventoryEntry$#{product_id}"
    end

    def reservation_stream order_id
      "Inventory::Reservation$#{order_id}"
    end

    def register_product(product_id)
      ProductCatalog::RegisterProduct.new(product_id: product_id, name: name)
    end

    def set_price(product_id)
      Pricing::SetPrice.new(product_id: product_id, price: 10)
    end

    def add_item(order_id, product_id)
      Pricing::AddItemToBasket.new(order_id: order_id, product_id: product_id)
    end

    def remove_item(order_id, product_id)
      Pricing::RemoveItemFromBasket.new(order_id: order_id, product_id: product_id)
    end

    def submit_order(order_id, customer_id)
      Ordering::SubmitOrder.new(order_id: order_id, customer_id: customer_id)
    end

    def register_customer(customer_id)
      Crm::RegisterCustomer.new(customer_id: customer_id, name: "Dummy")
    end

    def supply(product_id, quantity)
      Supply.new(product_id: product_id, quantity: quantity)
    end

    def cancel_order(order_id)
      Ordering::CancelOrder.new(order_id: order_id)
    end

    def confirm_order(order_id)
      Ordering::MarkOrderAsPaid.new(order_id: order_id)
    end
  end
end

