require_relative "test_helper"

module Processes
  class ThreePlusOneFreeTest < Test
    cover "Processes::ThreePlusOneFree*"

    def test_empty_basket_is_not_eligible_for_free_product
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      process = ThreePlusOneFree.new(cqrs)
      given(item_added_to_basket(order_id, product_id, 1) + item_removed_from_basket(order_id, product_id, 1)).each do |event|
        process.call(event)
      end
      assert_no_command
    end

    def test_one_item_in_basket_is_not_eligible_for_free_product
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      process = ThreePlusOneFree.new(cqrs)
      given(item_added_to_basket(order_id, product_id, 1)).each do |event|
        process.call(event)
      end
      assert_no_command
    end

    def test_four_items_in_basket_are_eligible_for_free_product
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      process = ThreePlusOneFree.new(cqrs)
      given([set_price(product_id, 20)])
      given(item_added_to_basket(order_id, product_id, 4)).each do |event|
        process.call(event)
      end
      assert_command(Pricing::MakeProductFreeForOrder.new(order_id: order_id, product_id: product_id))
    end

    def test_five_items_in_basket_are_eligible_for_free_product
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      process = ThreePlusOneFree.new(cqrs)
      given([set_price(product_id, 20)])
      given(item_added_to_basket(order_id, product_id, 5)).each do |event|
        process.call(event)
      end
      assert_command(Pricing::MakeProductFreeForOrder.new(order_id: order_id, product_id: product_id))
    end

    private

    def set_price(product_id, amount)
      Pricing::PriceSet.new(data: { product_id: product_id, price: amount })
    end

    def item_added_to_basket(order_id, product_id, times)
      times.times.collect do
        Ordering::ItemAddedToBasket.new(
          data: {
            order_id: order_id,
            product_id: product_id
          }
        )
      end
    end

    def item_removed_from_basket(order_id, product_id, times)
      times.times.collect do
        Ordering::ItemRemovedFromBasket.new(
          data: {
            order_id: order_id,
            product_id: product_id
          }
        )
      end
    end
  end
end
