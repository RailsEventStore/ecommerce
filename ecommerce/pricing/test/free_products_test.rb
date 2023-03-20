require_relative "test_helper"

module Pricing
  class FreeProductsTest < Test
    cover "Pricing*"

    def test_making_product_free_possible_when_order_is_eligible
      product_1_id = SecureRandom.uuid
      set_price(product_1_id, 20)
      order_id = SecureRandom.uuid
      add_item(order_id, product_1_id)
      add_item(order_id, product_1_id)
      add_item(order_id, product_1_id)
      add_item(order_id, product_1_id)
      stream = "Pricing::Order$#{order_id}"

      assert_events_contain(
        stream,
        ProductMadeFreeForOrder.new(
          data: {
            order_id: order_id,
            product_id: product_1_id
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 60,
            total_amount: 60
          }
        )
      ) do
        run_command(
          Pricing::MakeProductFreeForOrder.new(order_id: order_id, product_id: product_1_id)
        )
      end
    end

    def test_making_only_the_cheapest_product_free
      product_1_id = SecureRandom.uuid
      cheaper_product = SecureRandom.uuid
      set_price(product_1_id, 20)
      set_price(cheaper_product, 10)
      order_id = SecureRandom.uuid
      add_item(order_id, product_1_id)
      add_item(order_id, product_1_id)
      add_item(order_id, product_1_id)
      add_item(order_id, cheaper_product)
      stream = "Pricing::Order$#{order_id}"

      assert_events_contain(
        stream,
        ProductMadeFreeForOrder.new(
          data: {
            order_id: order_id,
            product_id: cheaper_product
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 60,
            total_amount: 60
          }
        ),
      ) do
        run_command(
          Pricing::MakeProductFreeForOrder.new(order_id: order_id, product_id: cheaper_product)
        )
      end
    end

    def test_making_product_free_not_possible_if_is_already_set
      product_1_id = SecureRandom.uuid
      set_price(product_1_id, 20)
      order_id = SecureRandom.uuid
      add_item(order_id, product_1_id)
      add_item(order_id, product_1_id)
      add_item(order_id, product_1_id)
      add_item(order_id, product_1_id)

      run_command(
        Pricing::MakeProductFreeForOrder.new(order_id: order_id, product_id: product_1_id)
      )

      assert_raises FreeProductAlreadyMade do
        run_command(
          Pricing::MakeProductFreeForOrder.new(order_id: order_id, product_id: product_1_id)
        )
      end
    end

    def test_making_product_free_possible_after_previous_free_product_was_removed
      product_1_id = SecureRandom.uuid
      set_price(product_1_id, 20)
      order_id = SecureRandom.uuid
      add_item(order_id, product_1_id)
      add_item(order_id, product_1_id)
      add_item(order_id, product_1_id)
      add_item(order_id, product_1_id)
      stream = "Pricing::Order$#{order_id}"

      run_command(
        Pricing::MakeProductFreeForOrder.new(order_id: order_id, product_id: product_1_id)
      )

      run_command(
        Pricing::RemovePriceItem.new(order_id: order_id, product_id: product_1_id)
      )

      run_command(
        Pricing::RemoveFreeProductFromOrder.new(order_id: order_id, product_id: product_1_id)
      )

      run_command(
        Pricing::AddPriceItem.new(order_id: order_id, product_id: product_1_id)
      )

      assert_events_contain(
        stream,
        ProductMadeFreeForOrder.new(
          data: {
            order_id: order_id,
            product_id: product_1_id
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 60,
            total_amount: 60
          }
        )
      ) do
        run_command(
          Pricing::MakeProductFreeForOrder.new(order_id: order_id, product_id: product_1_id)
        )
      end
    end

    def test_removing_free_product_possible_if_it_is_already_set
      product_1_id = SecureRandom.uuid
      set_price(product_1_id, 20)
      order_id = SecureRandom.uuid
      add_item(order_id, product_1_id)
      add_item(order_id, product_1_id)
      add_item(order_id, product_1_id)
      add_item(order_id, product_1_id)
      stream = "Pricing::Order$#{order_id}"

      run_command(
        Pricing::MakeProductFreeForOrder.new(order_id: order_id, product_id: product_1_id)
      )

      assert_events_contain(
        stream,
        FreeProductRemovedFromOrder.new(
          data: {
            order_id: order_id,
            product_id: product_1_id
          }
        ),
        OrderTotalValueCalculated.new(
          data: {
            order_id: order_id,
            discounted_amount: 80,
            total_amount: 80
          }
        )
      ) do
        run_command(
          Pricing::RemoveFreeProductFromOrder.new(order_id: order_id, product_id: product_1_id)
        )
      end
    end

    def test_removing_free_product_not_possible_if_is_not_set
      product_1_id = SecureRandom.uuid
      set_price(product_1_id, 20)
      order_id = SecureRandom.uuid
      add_item(order_id, product_1_id)

      assert_raises FreeProductNotExists do
        run_command(
          Pricing::RemoveFreeProductFromOrder.new(order_id: order_id, product_id: product_1_id)
        )
      end
    end

    def test_removing_free_product_twice_not_possible
      product_1_id = SecureRandom.uuid
      set_price(product_1_id, 20)
      order_id = SecureRandom.uuid
      add_item(order_id, product_1_id)
      add_item(order_id, product_1_id)
      add_item(order_id, product_1_id)
      add_item(order_id, product_1_id)

      run_command(
        Pricing::MakeProductFreeForOrder.new(order_id: order_id, product_id: product_1_id)
      )

      run_command(
        Pricing::RemoveFreeProductFromOrder.new(order_id: order_id, product_id: product_1_id)
      )

      assert_raises FreeProductNotExists do
        run_command(
          Pricing::RemoveFreeProductFromOrder.new(order_id: order_id, product_id: product_1_id)
        )
      end
    end

  end
end
