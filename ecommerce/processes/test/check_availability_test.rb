require_relative "test_helper"

module Processes
  class CheckAvailabilityTest < Test
    cover "Processes::CheckAvailabilityOnOrderItemAddedToBasket*"

    def test_inventory_available_error_is_raised
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      process = CheckAvailabilityOnOrderItemAddedToBasket.new(cqrs)
      given([item_added(order_id, product_id, 0)]).each do |event|
        process.call(event)
      end
      assert_command(Inventory::CheckAvailability.new(product_id: product_id, desired_quantity: 1))

      given([item_added(order_id, product_id, 1)]).each do |event|
        process.call(event)
      end
      assert_command(Inventory::CheckAvailability.new(product_id: product_id, desired_quantity: 2))
    end

    private

    def item_added order_id, product_id, quantity_before
      Ordering::ItemAddedToBasket.new(
        data: {
          order_id: order_id,
          product_id: product_id,
          quantity_before: quantity_before
        }
      )
    end
  end
end