require "test_helper"

module Returns
  class ReturnItemTest < InMemoryTestCase
    cover "Returns::ReturnItem*"

    def test_value_is_quantity_times_price
      item = ReturnItem.new(quantity: 3, price: 7)
      assert_equal(21, item.value)
    end

    def test_order_quantity_delegates_to_order_line
      item = ReturnItem.new
      item.order_line = order_line_with_quantity(5)
      assert_equal(5, item.order_quantity)
    end

    def test_max_quantity_is_true_when_equal_to_order_quantity
      item = ReturnItem.new(quantity: 4)
      item.order_line = order_line_with_quantity(4)
      assert(item.max_quantity?)
    end

    def test_max_quantity_is_false_when_less_than_order_quantity
      item = ReturnItem.new(quantity: 3)
      item.order_line = order_line_with_quantity(5)
      refute(item.max_quantity?)
    end

    def test_max_quantity_is_false_when_more_than_order_quantity
      item = ReturnItem.new(quantity: 6)
      item.order_line = order_line_with_quantity(5)
      refute(item.max_quantity?)
    end

    private

    def order_line_with_quantity(quantity)
      Struct.new(:quantity, :product_name).new(quantity, "Any")
    end
  end
end
