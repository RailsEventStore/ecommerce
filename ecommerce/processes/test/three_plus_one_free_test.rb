require_relative "test_helper"

module Processes
  class ThreePlusOneFreeTest < Test
    cover "Processes::ThreePlusOneFree*"

    def test_one_order_line_is_not_eligible_for_free_product
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      process = ThreePlusOneFree.new(event_store, command_bus)
      given(item_added_event(order_id, product_id, 22), process:)
      assert_no_command
    end

    def test_four_order_lines_are_eligible_for_free_product
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      process = ThreePlusOneFree.new(event_store, command_bus)
      given([set_price(product_id, 20)])
      given(item_added_event(order_id, product_id, 20, times: 4), process:)
      assert_command(Pricing::MakeProductFreeForOrder.new(order_id: order_id, product_id: product_id))
    end

    def test_remove_free_product_when_order_lines_qtn_is_less_than_four
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      process = ThreePlusOneFree.new(event_store, command_bus)
      given([set_price(product_id, 20)])
      given([item_added_event(order_id, product_id, 20, times: 4),
             product_made_for_free(order_id, product_id),
             item_removed_event(order_id, product_id, 20, times: 1),
             free_product_removed(order_id, product_id)
            ], process:)

      assert_all_commands(Pricing::MakeProductFreeForOrder.new(order_id: order_id, product_id: product_id),
                          Pricing::RemoveFreeProductFromOrder.new(order_id: order_id, product_id: product_id))
    end

    def test_change_free_product_if_new_order_line_is_the_cheapest
      product_id = SecureRandom.uuid
      cheapest_product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      process = ThreePlusOneFree.new(event_store, command_bus)
      given([set_price(product_id, 20)])
      given([set_price(cheapest_product_id, 1)])

      given([item_added_event(order_id, product_id, 20, times: 4),
             product_made_for_free(order_id, product_id),
             item_added_event(order_id, cheapest_product_id, 1),
             free_product_removed(order_id, product_id),
             product_made_for_free(order_id, cheapest_product_id)
            ], process:)

      assert_all_commands(Pricing::MakeProductFreeForOrder.new(order_id: order_id, product_id: product_id),
                          Pricing::RemoveFreeProductFromOrder.new(order_id: order_id, product_id: product_id),
                          Pricing::MakeProductFreeForOrder.new(order_id: order_id, product_id: cheapest_product_id))
    end

    def test_do_not_change_free_product_if_new_order_line_is_more_expensive
      product_id = SecureRandom.uuid
      more_expensive_product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      process = ThreePlusOneFree.new(event_store, command_bus)
      given([set_price(product_id, 20)])
      given([set_price(more_expensive_product_id, 50)])

      given([item_added_event(order_id, product_id, 20, times: 4),
             product_made_for_free(order_id, product_id),
             item_added_event(order_id, more_expensive_product_id, 50)
            ], process:)

      assert_all_commands(Pricing::MakeProductFreeForOrder.new(order_id: order_id, product_id: product_id))
    end

    def test_change_free_product_if_the_cheapest_order_line_is_removed
      product_id = SecureRandom.uuid
      cheapest_product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      process = ThreePlusOneFree.new(event_store, command_bus)
      given([set_price(product_id, 20)])
      given([set_price(cheapest_product_id, 1)])

      given([item_added_event(order_id, product_id, 20, times: 4),
             product_made_for_free(order_id, product_id),
             item_added_event(order_id, cheapest_product_id, 1),
             free_product_removed(order_id, product_id),
             product_made_for_free(order_id, cheapest_product_id),
             item_removed_event(order_id, cheapest_product_id, 1),
             free_product_removed(order_id, cheapest_product_id),
             product_made_for_free(order_id, product_id),
            ], process:)

      assert_all_commands(Pricing::MakeProductFreeForOrder.new(order_id: order_id, product_id: product_id),
                          Pricing::RemoveFreeProductFromOrder.new(order_id: order_id, product_id: product_id),
                          Pricing::MakeProductFreeForOrder.new(order_id: order_id, product_id: cheapest_product_id),
                          Pricing::RemoveFreeProductFromOrder.new(order_id: order_id, product_id: cheapest_product_id),
                          Pricing::MakeProductFreeForOrder.new(order_id: order_id, product_id: product_id)
      )
    end

    private

    def set_price(product_id, amount)
      Pricing::PriceSet.new(data: { product_id: product_id, price: amount })
    end

    def item_added_event(order_id, product_id, price, times: 1)
      times.times.collect do
        Pricing::PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            price: price
          }
        )
      end
    end

    def item_removed_event(order_id, product_id, price, times: 1)
      times.times.collect do
        Pricing::PriceItemRemoved.new(
          data: { order_id:, product_id:, price: }
        )
      end
    end

    def product_made_for_free(order_id, product_id)
      [
        Pricing::ProductMadeFreeForOrder.new(
          data: {
            order_id: order_id,
            product_id: product_id
          }
        )
      ]
    end

    def free_product_removed(order_id, product_id)
      [
        Pricing::FreeProductRemovedFromOrder.new(
          data: {
            order_id: order_id,
            product_id: product_id
          }
        )
      ]
    end
  end
end
