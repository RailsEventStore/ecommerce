require_relative 'test_helper'
module Stores
  class StoreNameTest < Test
    cover "Stores*"

    def test_creates_store_name_with_valid_value
      store_name = StoreName.new(value: "Store 1")
      assert_equal "Store 1", store_name.value
    end

    def test_rejects_nil_value
      assert_raises(ArgumentError) do
        StoreName.new(value: nil)
      end
    end

    def test_rejects_empty_value
      assert_raises(ArgumentError) do
        StoreName.new(value: "")
      end
    end
  end
end
