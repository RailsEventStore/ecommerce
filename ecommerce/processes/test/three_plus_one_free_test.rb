require_relative "test_helper"

module Processes
  class ThreePlusOneFreeTest < Test
    cover "Processes::ThreePlusOneFree*"

    def test_when_order_lines_qty_has_never_reached_the_min_qty_limit_for_free_product
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      process = ThreePlusOneFree.new(cqrs)
      given(item_added_event(order_id, product_id, 1) + item_removed_event(order_id, product_id, 1)).each do |event|
        process.call(event)
      end
      assert_no_command
    end

    def test_one_order_line_is_not_eligible_for_free_product
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      process = ThreePlusOneFree.new(cqrs)
      given(item_added_event(order_id, product_id, 1)).each do |event|
        process.call(event)
      end
      assert_no_command
    end

    def test_four_order_lines_are_eligible_for_free_product
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      process = ThreePlusOneFree.new(cqrs)
      given([set_price(product_id, 20)])
      given(item_added_event(order_id, product_id, 4)).each do |event|
        process.call(event)
      end
      assert_command(Pricing::MakeProductFreeForOrder.new(order_id: order_id, product_id: product_id))
    end

    def test_five_order_lines_are_eligible_for_free_product
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      process = ThreePlusOneFree.new(cqrs)
      given([set_price(product_id, 20)])
      given(item_added_event(order_id, product_id, 5)).each do |event|
        process.call(event)
      end
      assert_command(Pricing::MakeProductFreeForOrder.new(order_id: order_id, product_id: product_id))
    end

    private

    def set_price(product_id, amount)
      Pricing::PriceSet.new(data: { product_id: product_id, price: amount })
    end

    def item_added_event(order_id, product_id, times)
      times.times.collect do
        Pricing::PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id
          }
        )
      end
    end

    def item_removed_event(order_id, product_id, times)
      times.times.collect do
        Pricing::PriceItemRemoved.new(
          data: {
            order_id: order_id,
            product_id: product_id
          }
        )
      end
    end
  end
end
