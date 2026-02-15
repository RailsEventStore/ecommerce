require "test_helper"

module Orders
  class OrderLineTest < InMemoryTestCase
    cover "Orders*"

    def configure(event_store, _command_bus)
      Orders::Configuration.new.call(event_store)
    end

    def test_calculates_value_correctly
      order_line = OrderLine.new(price: 10, quantity: 1)
      assert_equal 10, order_line.value

      order_line = OrderLine.new(price: 10, quantity: 0)
      assert_equal 0, order_line.value

      order_line = OrderLine.new(price: 10, quantity: 10)
      assert_equal 100, order_line.value
    end
  end
end