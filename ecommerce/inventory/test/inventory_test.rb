require 'test_helper'

module Inventory
  class InventoryTest < Ecommerce::InMemoryTestCase
    include TestPlumbing

    cover 'Inventory*'

    def test_if_stock_level_changes_with_supply_command
      product_id = SecureRandom.uuid
      stream = "Inventory::InventoryEntry$#{product_id}"
      assert_events(stream, StockLevelChanged.new(data: { product_id: product_id, quantity: 1, stock_level: 1 })) do
        supply(product_id, 1)
      end
    end

    def test_if_reservation_adjusts_on_item_added_to_and_removed_from_basket
      product_id = SecureRandom.uuid
      register_product(product_id, "test")
      set_price(product_id, 20)
      order_id = SecureRandom.uuid
      stream = "Inventory::Reservation$#{order_id}"
      assert_events(stream, ReservationAdjusted.new(data: { product_id: product_id, quantity: 1 })) do
        add_item(order_id, product_id)
      end
      assert_events(stream, ReservationAdjusted.new(data: { product_id: product_id, quantity: -1 })) do
        remove_item(order_id, product_id)
      end
    end

    def test_if_stock_gets_reserved_on_reservation_submission
      product_id = SecureRandom.uuid
      register_product(product_id, "test")
      set_price(product_id, 20)
      supply(product_id, 1)
      order_id = SecureRandom.uuid
      add_item(order_id, product_id)
      customer_id = SecureRandom.uuid
      register_customer(customer_id, 'test')

      reservation_stream = "Inventory::Reservation$#{order_id}"
      product_stream = "Inventory::InventoryEntry$#{product_id}"
      assert_events(reservation_stream, ReservationSubmitted.new(data: { reservation_items: [product_id: product_id, quantity: 1] })) do
        assert_events(product_stream, StockReserved.new(data: { product_id: product_id, quantity: 1 })) do
          submit_order(order_id, customer_id)
        end
      end
    end

    def test_if_stock_gets_released_on_reservation_cancelation
      product_id = SecureRandom.uuid
      register_product(product_id, "test")
      set_price(product_id, 20)
      supply(product_id, 1)
      order_id = SecureRandom.uuid
      add_item(order_id, product_id)
      customer_id = SecureRandom.uuid
      register_customer(customer_id, 'test')
      submit_order(order_id, customer_id)

      reservation_stream = "Inventory::Reservation$#{order_id}"
      product_stream = "Inventory::InventoryEntry$#{product_id}"
      assert_events(reservation_stream, ReservationCanceled.new(data: { reservation_items: [product_id: product_id, quantity: 1] })) do
        assert_events(product_stream, StockReleased.new(data: { product_id: product_id, quantity: 1 })) do
          cancel_order(order_id)
        end
      end
    end

    def test_if_stock_level_changes_on_reservation_completion
      product_id = SecureRandom.uuid
      register_product(product_id, "test")
      set_price(product_id, 20)
      supply(product_id, 1)
      order_id = SecureRandom.uuid
      add_item(order_id, product_id)
      customer_id = SecureRandom.uuid
      register_customer(customer_id, 'test')
      submit_order(order_id, customer_id)

      reservation_stream = "Inventory::Reservation$#{order_id}"
      product_stream = "Inventory::InventoryEntry$#{product_id}"
      assert_events(reservation_stream, ReservationCompleted.new(data: { reservation_items: [product_id: product_id, quantity: 1] })) do
        assert_events(product_stream,
                      StockReleased.new(data: { product_id: product_id, quantity: 1 }),
                      StockLevelChanged.new(data: { product_id: product_id, quantity: -1, stock_level: 0 })) do
          confirm_order(order_id)
        end
      end
    end

    def test_if_prevents_from_order_submission_when_out_of_stock
      product_id = SecureRandom.uuid
      register_product(product_id, "test")
      set_price(product_id, 20)
      supply(product_id, 1)
      order_id = SecureRandom.uuid
      2.times { add_item(order_id, product_id) }
      customer_id = SecureRandom.uuid
      register_customer(customer_id, 'test')
      assert_raises(Inventory::InventoryEntry::InventoryNotAvailable) do
        submit_order(order_id, customer_id)
      end
    end

    def test_unless_prevents_from_order_submission_when_stock_level_is_undefined
      product_id = SecureRandom.uuid
      register_product(product_id, "test")
      set_price(product_id, 20)
      order_id = SecureRandom.uuid
      add_item(order_id, product_id)
      customer_id = SecureRandom.uuid
      register_customer(customer_id, 'test')

      product_stream = "Inventory::InventoryEntry$#{product_id}"
      assert_nothing_raised do
        assert_events(product_stream) do
          submit_order(order_id, customer_id)
        end
      end
    end

    private

    def register_product(product_id, product_name)
      run_command(ProductCatalog::RegisterProduct.new(product_id: product_id, name: name))
    end

    def set_price(product_id, amount)
      run_command(Pricing::SetPrice.new(product_id: product_id, price: amount))
    end

    def add_item(order_id, product_id)
      run_command(Pricing::AddItemToBasket.new(order_id: order_id, product_id: product_id))
    end

    def remove_item(order_id, product_id)
      run_command(Pricing::RemoveItemFromBasket.new(order_id: order_id, product_id: product_id))
    end

    def submit_order(order_id, customer_id)
      run_command(Ordering::SubmitOrder.new(order_id: order_id, customer_id: customer_id))
    end

    def register_customer(customer_id, name)
      run_command(Crm::RegisterCustomer.new(customer_id: customer_id, name: name))
    end

    def supply(product_id, quantity)
      run_command(Supply.new(product_id: product_id, quantity: quantity))
    end

    def cancel_order(order_id)
      run_command(Ordering::CancelOrder.new(order_id: order_id))
    end

    def confirm_order(order_id)
      run_command(Ordering::MarkOrderAsPaid.new(order_id: order_id))
    end
  end
end

