require_relative "test_helper"

module Ordering
  class OrderTest < Test
    cover "Ordering::Order"

    def setup
      super
      @order_id = SecureRandom.uuid
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
      assert_equal({ @product_id => 2 }, order.unpublished_events.to_a.last.data[:order_lines])
    end

    def test_order_lines_after_adding_twice_and_remove_once
      order = Order.new(@order_id)
      order.add_item(@product_id)
      order.add_item(@product_id)
      order.remove_item(@product_id)
      order.submit(NumberGenerator.new.call)
      assert_equal({ @product_id => 1 }, order.unpublished_events.to_a.last.data[:order_lines])
    end

    def test_disallowed_order_state_transitions
      draft_order.submit(NumberGenerator.new.call)
      assert_raises(Order::InvalidState) { draft_order.accept }
      assert_raises(Order::InvalidState) { draft_order.reject }
      draft_order.expire

      assert_raises(Order::InvalidState) { submitted_order.submit(NumberGenerator.new.call) }
      submitted_order.accept
      submitted_order.reject
      assert_raises(Order::InvalidState) { submitted_order.expire }

      placed_order.submit(NumberGenerator.new.call)
      assert_raises(Order::InvalidState) { placed_order.accept }
      assert_raises(Order::InvalidState) { placed_order.reject }
      assert_raises(Order::InvalidState) { placed_order.expire }

      assert_raises(Order::InvalidState) { expired_order.submit(NumberGenerator.new.call) }
      assert_raises(Order::InvalidState) { rejected_order.accept }
      assert_raises(Order::InvalidState) { rejected_order.reject }
      rejected_order.expire

      assert_raises(Order::InvalidState) { expired_order.submit(NumberGenerator.new.call) }
      assert_raises(Order::InvalidState) { expired_order.accept }
      assert_raises(Order::InvalidState) { expired_order.reject }
      assert_raises(Order::InvalidState) { expired_order.expire }
    end

    def draft_order
      Order.new(@order_id)
    end

    def submitted_order
      draft_order.tap do |order|
        order.submit(NumberGenerator.new.call)
      end
    end

    def placed_order
      submitted_order.tap do |order|
        order.accept
      end
    end

    def rejected_order
      submitted_order.tap do |order|
        order.reject
      end
    end

    def expired_order
      draft_order.tap do |order|
        order.expire
      end
    end
  end
end
