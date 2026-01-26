require_relative "test_helper"

module Ordering
  class ReturnItemsListTest < Test

    def test_initialize
      list = ItemsList.new

      assert_equal 0, list.return_items.size
    end

    def test_increase_item_quantity
      product_one_id = SecureRandom.uuid
      product_two_id = SecureRandom.uuid
      list = ItemsList.new

      list.increase_quantity(product_one_id)

      assert_equal 1, list.return_items.size
      assert_equal 1, list.quantity(product_one_id)

      list.increase_quantity(product_two_id)

      assert_equal 2, list.return_items.size
      assert_equal 1, list.quantity(product_two_id)
    end

    def test_decrease_item_quantity
      product_id = SecureRandom.uuid
      list = ItemsList.new

      list.increase_quantity(product_id)
      list.increase_quantity(product_id)

      assert_equal 1, list.return_items.size
      assert_equal 2, list.quantity(product_id)

      list.decrease_quantity(product_id)

      assert_equal 1, list.return_items.size
      assert_equal 1, list.quantity(product_id)

      list.decrease_quantity(product_id)

      assert_equal 0, list.return_items.size
    end
  end
end
