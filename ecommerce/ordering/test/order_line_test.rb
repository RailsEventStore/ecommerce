module Ordering
  class OrderLineTest < Test
    def test_quantity_changes
      product_id = SecureRandom.uuid
      order_line = OrderLine.new(product_id)

      order_line.increase_quantity
      refute(order_line.empty?)
      assert_equal(1, order_line.quantity)
      order_line.decrease_quantity
      assert(order_line.empty?)
      assert_equal(0, order_line.quantity)
    end

    def test_comparability
      product_id = SecureRandom.uuid
      product_order_line = OrderLine.new(product_id)
      the_same_product_order_line = OrderLine.new(product_id)
      other_product_id = SecureRandom.uuid
      other_product_order_line = OrderLine.new(other_product_id)

      assert(product_order_line == product_order_line)
      assert(product_order_line == the_same_product_order_line)
      refute(product_order_line == other_product_order_line)
    end
  end
end