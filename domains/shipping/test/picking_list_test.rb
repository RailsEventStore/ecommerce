require_relative "test_helper"

module Shipping
  class PickingListTest < Test

    def test_initialize
      list = PickingList.new

      assert_equal 0, list.items.size
    end

    def test_increase_item_quantity
      product_one_id = SecureRandom.uuid
      product_two_id = SecureRandom.uuid
      list = PickingList.new

      list.increase_item_quantity(product_one_id)

      assert_equal 1, list.items.size
      assert_equal 1, list.find_item(product_one_id).quantity

      list.increase_item_quantity(product_two_id)

      assert_equal 2, list.items.size
      assert_equal 1, list.find_item(product_two_id).quantity
    end

    def test_decrease_item_quantity
      product_id = SecureRandom.uuid
      list = PickingList.new

      list.increase_item_quantity(product_id)
      list.increase_item_quantity(product_id)

      assert_equal 1, list.items.size
      assert_equal 2, list.find_item(product_id).quantity

      list.decrease_item_quantity(product_id)

      assert_equal 1, list.items.size
      assert_equal 1, list.find_item(product_id).quantity

      list.decrease_item_quantity(product_id)

      assert_equal 0, list.items.size
    end
  end
end