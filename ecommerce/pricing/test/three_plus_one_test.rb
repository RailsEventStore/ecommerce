require_relative "test_helper"

module Pricing
  class ThreePlusOneTest < Test
    cover "Pricing::Offer*"

    def test_given_three_items_are_added_when_forth_item_is_added_then_the_last__item_is_free
      product_id = SecureRandom.uuid
      set_price(product_id, 20)
      order_id = SecureRandom.uuid
      stream = "Pricing::Offer$#{order_id}"
      assert_events(
        stream,
        PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            base_price: 20,
            price: 20,
            base_total_value: 20,
            total_value: 20,
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 20,
            total_amount: 20
          }
        ),
        PriceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity: 1,
            amount: 20,
            discounted_amount: 20,
          }
        )
      ) { add_item(order_id, product_id) }

      assert_events(
        stream,
        PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            base_price: 20,
            price: 20,
            base_total_value: 40,
            total_value: 40,
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 40,
            total_amount: 40
          }
        ),
        PriceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity: 2,
            amount: 40,
            discounted_amount: 40,
          }
        )
      ) { add_item(order_id, product_id) }

      assert_events(
        stream,
        PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            base_price: 20,
            price: 20,
            base_total_value: 60,
            total_value: 60,
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 60,
            total_amount: 60
          }
        ),
        PriceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity: 3,
            amount: 60,
            discounted_amount: 60,
          }
        )
      ) { add_item(order_id, product_id) }

      assert_events(
        stream,
        PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            base_price: 20,
            price: 0,
            base_total_value: 80,
            total_value: 60,
            applied_promotion: Pricing::Discounts::ThreePlusOneGratis.to_s
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 60,
            total_amount: 80
          }
        ),
        PriceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity: 4,
            amount: 80,
            discounted_amount: 60,
          }
        )
      ) { add_item(order_id, product_id, promotion: true) }
    end

    def test_given_3_plus_one__when_10_percent_discount_for_offer__then_offer_price_includes_both_discounts
      product_id = SecureRandom.uuid
      set_price(product_id, 20)
      order_id = SecureRandom.uuid
      stream = "Pricing::Offer$#{order_id}"
      assert_events(
        stream,
        PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            base_price: 20,
            price: 20,
            base_total_value: 20,
            total_value: 20,
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 20,
            total_amount: 20
          }
        ),
        PriceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity: 1,
            amount: 20,
            discounted_amount: 20,
          }
        )
      ) { add_item(order_id, product_id) }

      assert_events(
        stream,
        PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            base_price: 20,
            price: 20,
            base_total_value: 40,
            total_value: 40,
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 40,
            total_amount: 40
          }
        ),
        PriceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity: 2,
            amount: 40,
            discounted_amount: 40,
          }
        )
      ) { add_item(order_id, product_id) }

      assert_events(
        stream,
        PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            base_price: 20,
            price: 20,
            base_total_value: 60,
            total_value: 60,
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 60,
            total_amount: 60
          }
        ),
        PriceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity: 3,
            amount: 60,
            discounted_amount: 60,
          }
        )
      ) { add_item(order_id, product_id) }

      assert_events(
        stream,
        PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            base_price: 20,
            price: 0,
            base_total_value: 80,
            total_value: 60,
            applied_promotion: Pricing::Discounts::ThreePlusOneGratis.to_s
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 60,
            total_amount: 80
          }
        ),
        PriceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity: 4,
            amount: 80,
            discounted_amount: 60,
          }
        )
      ) { add_item(order_id, product_id, promotion: true) }
      assert_events(
        stream,
        PercentageDiscountSet.new(
          data: {
            order_id: order_id,
            type: Discounts::GENERAL_DISCOUNT,
            amount: 10,
            base_total_value: 80,
            total_value: 54
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 54,
            total_amount: 80
          }
        ),
        PriceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity: 4,
            amount: 80,
            discounted_amount: 54,
          }
        )
      ) { set_percentage_discount(order_id, 10) }
    end

    def test_given_three_plus_one_promotion_when_five_items_are_added_then_only_one_item_is_free
      product_id = SecureRandom.uuid
      set_price(product_id, 20)
      order_id = SecureRandom.uuid
      stream = "Pricing::Offer$#{order_id}"

      3.times { add_item(order_id, product_id, promotion: true) }

      assert_events(
        stream,
        PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            base_price: 20,
            price: 0,
            base_total_value: 80,
            total_value: 60,
            applied_promotion: Pricing::Discounts::ThreePlusOneGratis.to_s
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            total_amount: 80,
            discounted_amount: 60
          }
        ),
        PriceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity: 4,
            amount: 80,
            discounted_amount: 60,
          }
        )
      ) { add_item(order_id, product_id, promotion: true) }

      assert_events(
        stream,
        PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            base_price: 20,
            price: 20,
            base_total_value: 100,
            total_value: 80,
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            total_amount: 100,
            discounted_amount: 80
          }
        ),
        PriceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity: 5,
            amount: 100,
            discounted_amount: 80,
          }
        )
      ) { add_item(order_id, product_id, promotion: true) }
    end

    def test_given_three_plus_one_promotion_when_eight_items_are_added_then_two_items_are_free
      product_id = SecureRandom.uuid
      set_price(product_id, 20)
      order_id = SecureRandom.uuid
      stream = "Pricing::Offer$#{order_id}"

      7.times { add_item(order_id, product_id, promotion: true) }

      assert_events(
        stream,
        PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            base_price: 20,
            price: 0,
            base_total_value: 160,
            total_value: 120,
            applied_promotion: Pricing::Discounts::ThreePlusOneGratis.to_s
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            total_amount: 160,
            discounted_amount: 120
          }
        ),
        PriceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity: 8,
            amount: 160,
            discounted_amount: 120,
          }
        )
      ) { add_item(order_id, product_id, promotion: true) }
    end

    def test_given_three_plus_one_is_applied_when_item_is_removed_then_the_discount_is_removed
      product_id = SecureRandom.uuid
      set_price(product_id, 20)
      order_id = SecureRandom.uuid
      stream = "Pricing::Offer$#{order_id}"

      4.times { add_item(order_id, product_id, promotion: true) }

      assert_events(
        stream,
        PriceItemRemoved.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            base_price: 20,
            price: 0,
            base_total_value: 60,
            total_value: 60
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            total_amount: 60,
            discounted_amount: 60
          }
        ),
        PriceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity: 3,
            amount: 60,
            discounted_amount: 60,
          }
        )
      ) { remove_item(order_id, product_id) }
    end

    def test_given_three_items_added_to_basket_and_no_three_plus_one_promotion_when_fourth_is_added_then_price_is_not_discounted
      product_id = SecureRandom.uuid
      set_price(product_id, 20)
      order_id = SecureRandom.uuid
      stream = "Pricing::Offer$#{order_id}"

      3.times { add_item(order_id, product_id) }

      assert_events(
        stream,
        PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            base_price: 20,
            price: 20,
            base_total_value: 80,
            total_value: 80
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            total_amount: 80,
            discounted_amount: 80
          }
        ),
        PriceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity: 4,
            amount: 80,
            discounted_amount: 80,
          }),
      ) { add_item(order_id, product_id) }
    end

    def test_given_three_items_in_basket_when_different_one_is_added_then_price_is_not_discounted
      product_id = SecureRandom.uuid
      different_product_id = SecureRandom.uuid
      set_price(product_id, 20)
      set_price(different_product_id, 50)
      order_id = SecureRandom.uuid
      stream = "Pricing::Offer$#{order_id}"

      3.times { add_item(order_id, product_id) }

      assert_events(
        stream,
        PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: different_product_id,
            base_price: 50,
            price: 50,
            base_total_value: 110,
            total_value: 110
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            total_amount: 110,
            discounted_amount: 110
          }
        ),
        PriceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity: 3,
            amount: 60,
            discounted_amount: 60,
          }),
        PriceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: different_product_id,
            quantity: 1,
            amount: 50,
            discounted_amount: 50,
          })
      ) { add_item(order_id, different_product_id) }
    end

    def test_given_two_sets_of_three_items_in_basket_when_added_forth_item_then_price_is_discounted_for_that_item
      product_id = SecureRandom.uuid
      different_product_id = SecureRandom.uuid
      set_price(product_id, 20)
      set_price(different_product_id, 50)
      order_id = SecureRandom.uuid
      stream = "Pricing::Offer$#{order_id}"

      3.times { add_item(order_id, product_id, promotion: true) }
      3.times { add_item(order_id, different_product_id, promotion: true) }

      assert_events(
        stream,
        PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: different_product_id,
            base_price: 50,
            price: 0,
            base_total_value: 260,
            total_value: 210,
            applied_promotion: Pricing::Discounts::ThreePlusOneGratis.to_s
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            total_amount: 260,
            discounted_amount: 210
          }
        ),
        PriceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            quantity: 3,
            amount: 60,
            discounted_amount: 60,
          }),
        PriceItemValueCalculated.new(
          data: {
            order_id: order_id,
            product_id: different_product_id,
            quantity: 4,
            amount: 200,
            discounted_amount: 150,
          })
      ) { add_item(order_id, different_product_id, promotion: true) }
    end
  end
end
