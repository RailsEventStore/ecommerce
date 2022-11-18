require "test_helper"

module ClientOrders
  class OrderLineTest < InMemoryTestCase
    cover "ClientOrders*"

    def test_calculates_value_correctly
      order_line = OrderLine.new(product_price: 10, product_quantity: 1)
      assert_equal 10, order_line.value

      order_line = OrderLine.new(product_price: 10, product_quantity: 0)
      assert_equal 0, order_line.value

      order_line = OrderLine.new(product_price: 10, product_quantity: 10)
      assert_equal 100, order_line.value
    end
  end
end