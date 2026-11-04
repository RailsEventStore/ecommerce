require_relative "test_helper"

module Pricing
  class OfferLineTest < Test
    cover "Pricing::OfferLine*"

    def test_addition_captures_the_price_of_each_unit
      order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid

      assert_events(
        line_stream(order_id, product_id),
        PriceItemAdded.new(data: { order_id: order_id, product_id: product_id, price: 40 }),
        PriceItemAdded.new(data: { order_id: order_id, product_id: product_id, price: 20.25 })
      ) do
        with_line(order_id, product_id) { |line| line.add_item(40) }
        with_line(order_id, product_id) { |line| line.add_item(20.25) }
      end
    end

    def test_removal_chooses_one_cheapest_unit_after_reloading
      order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      [40, 20.25, 20.25, 30.5].each do |price|
        with_line(order_id, product_id) { |line| line.add_item(price) }
      end

      [20.25, 20.25, 30.5, 40].each do |price|
        assert_removal(order_id, product_id, price)
      end

      assert_no_events(line_stream(order_id, product_id)) do
        assert_raises(OfferLine::IsEmpty) do
          with_line(order_id, product_id, &:remove_item)
        end
      end

      with_line(order_id, product_id) { |line| line.add_item(17) }
      assert_removal(order_id, product_id, 17)
    end

    def test_prices_are_scoped_to_one_product_in_one_offer
      order_id = SecureRandom.uuid
      other_order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      other_product_id = SecureRandom.uuid
      with_line(order_id, product_id) { |line| line.add_item(30) }
      with_line(order_id, other_product_id) { |line| line.add_item(17) }
      with_line(other_order_id, product_id) { |line| line.add_item(9) }

      assert_removal(order_id, product_id, 30)
      assert_removal(other_order_id, product_id, 9)
      assert_removal(order_id, other_product_id, 17)
    end

    def test_removing_a_line_without_units_does_not_publish_an_event
      order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid

      assert_no_events(line_stream(order_id, product_id)) do
        assert_raises(OfferLine::IsEmpty) do
          with_line(order_id, product_id, &:remove_item)
        end
      end
    end

    private

    def with_line(order_id, product_id, &block)
      Infra::AggregateRootRepository.new(event_store).with_aggregate(
        OfferLine,
        "#{order_id}:#{product_id}",
        &block
      )
    end

    def line_stream(order_id, product_id)
      "Pricing::OfferLine$#{order_id}:#{product_id}"
    end

    def assert_removal(order_id, product_id, price)
      assert_events(
        line_stream(order_id, product_id),
        PriceItemRemoved.new(data: { order_id: order_id, product_id: product_id, price: price })
      ) { with_line(order_id, product_id, &:remove_item) }
    end
  end
end
