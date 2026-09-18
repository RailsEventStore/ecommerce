require_relative "test_helper"

module Inventory
  class SupplyCommandTest < Test
    PRODUCT_ID = "123e4567-e89b-42d3-a456-426614174000"

    def test_coerces_quantity
      assert_equal(2, Supply.new(PRODUCT_ID, "2").quantity)
    end

    def test_rejects_invalid_product_id
      assert_raises(Infra::Command::Invalid) do
        Supply.new("not-a-uuid", 2)
      end

      assert_raises(Infra::Command::Invalid) do
        Supply.new(Object.new, 2)
      end
    end

    def test_rejects_uuid_with_wrong_version
      assert_raises(Infra::Command::Invalid) do
        Supply.new("123e4567-e89b-12d3-a456-426614174000", 2)
      end
    end

    def test_rejects_uuid_with_wrong_variant
      assert_raises(Infra::Command::Invalid) do
        Supply.new("123e4567-e89b-42d3-7456-426614174000", 2)
      end
    end

    def test_rejects_non_positive_quantity
      assert_raises(Infra::Command::Invalid) do
        Supply.new(PRODUCT_ID, 0)
      end
    end

    def test_rejects_invalid_quantity
      assert_raises(Infra::Command::Invalid) do
        Supply.new(PRODUCT_ID, "two")
      end

      assert_raises(Infra::Command::Invalid) do
        Supply.new(PRODUCT_ID, Object.new)
      end
    end
  end
end
