require_relative "test_helper"

module Pricing
  class OfferLineTest < Test
    cover "Pricing::OfferLine*"
    cover "Pricing::OnAddItemToBasket*"
    cover "Pricing::OnRemoveItemFromBasket*"

    def test_addition_captures_the_price_of_each_unit
      order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid

      assert_events(
        line_stream(order_id, product_id),
        PriceItemAdded.new(data: { order_id: order_id, product_id: product_id, price: 40 }),
        PriceItemAdded.new(data: { order_id: order_id, product_id: product_id, price: 20.25 })
      ) do
        run_command(AddPriceItem.new(order_id, product_id, 40))
        run_command(AddPriceItem.new(order_id, product_id, "20.25"))
      end
    end

    def test_removal_chooses_one_cheapest_unit_after_reloading
      order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      ["40", "20.25", "20.25", "30.5"].each do |price|
        run_command(AddPriceItem.new(order_id, product_id, price))
      end

      [20.25, 20.25, 30.5, 40].each do |price|
        assert_removal(order_id, product_id, price)
      end

      assert_no_events(line_stream(order_id, product_id)) do
        assert_raises(OfferLine::IsEmpty) do
          remove_item(order_id, product_id)
        end
      end

      run_command(AddPriceItem.new(order_id, product_id, 17))
      assert_removal(order_id, product_id, 17)
    end

    def test_prices_are_scoped_to_one_product_in_one_offer
      order_id = SecureRandom.uuid
      other_order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      other_product_id = SecureRandom.uuid
      run_command(AddPriceItem.new(order_id, product_id, 30))
      run_command(AddPriceItem.new(order_id, other_product_id, 17))
      run_command(AddPriceItem.new(other_order_id, product_id, 9))

      assert_removal(order_id, product_id, 30)
      assert_removal(other_order_id, product_id, 9)
      assert_removal(order_id, other_product_id, 17)
    end

    def test_removing_a_line_without_units_does_not_publish_an_event
      order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid

      assert_no_events(line_stream(order_id, product_id)) do
        assert_raises(OfferLine::IsEmpty) do
          remove_item(order_id, product_id)
        end
      end
    end

    def test_basket_edits_do_not_grow_the_offer_stream
      order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      run_command(DraftOffer.new(order_id))

      assert_no_events("Pricing::Offer$#{order_id}") do
        run_command(AddPriceItem.new(order_id, product_id, 20))
        remove_item(order_id, product_id)
      end
    end

    private

    def line_stream(order_id, product_id)
      "Pricing::OfferLine$#{order_id}:#{product_id}"
    end

    def assert_removal(order_id, product_id, price)
      assert_events(
        line_stream(order_id, product_id),
        PriceItemRemoved.new(data: { order_id: order_id, product_id: product_id, price: price })
      ) { remove_item(order_id, product_id) }
    end
  end
end
