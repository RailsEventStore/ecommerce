require_relative "test_helper"

module Shipping
  class PickingListItemTest < Test

    def test_initialize
      product_id = SecureRandom.uuid
      list_item = PickingListItem.new(product_id)

      assert_equal product_id, list_item.product_id
      assert_equal 0, list_item.quantity
    end

    def test_increase
      product_id = SecureRandom.uuid
      list_item = PickingListItem.new(product_id)

      list_item.increase

      assert_equal 1, list_item.quantity
    end

    def test_decrease
      product_id = SecureRandom.uuid
      list_item = PickingListItem.new(product_id)

      list_item.increase
      list_item.decrease

      assert_equal 0, list_item.quantity
    end
  end
end