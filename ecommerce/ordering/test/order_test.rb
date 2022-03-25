require_relative "test_helper"

module Ordering
  class OrderTest < Test
    cover "Ordering::Order"

    def setup
      super
      @order_id   = SecureRandom.uuid
      @product_id = SecureRandom.uuid
      @customer_id = SecureRandom.uuid
    end

    def test_order_lines_are_empty_after_adding_and_removing
      order = Order.new(@order_id)
      order.add_item(@product_id)
      order.remove_item(@product_id)
      order.submit(NumberGenerator.new.call)
      assert_equal({}, order.unpublished_events.to_a.last.data[:order_lines])
    end

    def test_order_lines_with_the_same_product_twice
      order = Order.new(@order_id)
      order.add_item(@product_id)
      order.add_item(@product_id)
      order.submit(NumberGenerator.new.call)
      assert_equal({@product_id => 2}, order.unpublished_events.to_a.last.data[:order_lines])
    end

    def test_order_lines_after_adding_twice_and_remove_once
      order = Order.new(@order_id)
      order.add_item(@product_id)
      order.add_item(@product_id)
      order.remove_item(@product_id)
      order.submit(NumberGenerator.new.call)
      assert_equal({@product_id => 1}, order.unpublished_events.to_a.last.data[:order_lines])
    end
  end
end
