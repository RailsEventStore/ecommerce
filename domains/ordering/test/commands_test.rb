require_relative "test_helper"

module Ordering
  class CommandsTest < Test
    cover "Ordering*"

    RETURN_ID = "123e4567-e89b-42d3-a456-426614174000"
    ORDER_ID = "223e4567-e89b-42d3-a456-426614174000"
    PRODUCT_ID = "323e4567-e89b-42d3-a456-426614174000"
    PRODUCTS = [{ product_id: PRODUCT_ID, quantity: 2 }].freeze

    def test_exposes_attributes
      command = AddItemToReturn.new(RETURN_ID, ORDER_ID, PRODUCT_ID)
      assert_equal(RETURN_ID, command.return_id)
      assert_equal(ORDER_ID, command.order_id)
      assert_equal(PRODUCT_ID, command.product_id)
      assert_equal(RETURN_ID, command.aggregate_id)
      assert_equal(PRODUCTS, CreateDraftReturn.new(RETURN_ID, ORDER_ID, PRODUCTS).returnable_products)
    end

    def test_rejects_invalid_return_id
      constructors.each do |constructor|
        assert_raises(Infra::Command::Invalid) { constructor.call("not-a-uuid") }
        assert_raises(Infra::Command::Invalid) { constructor.call(Object.new) }
        assert_raises(Infra::Command::Invalid) { constructor.call("123e4567-e89b-12d3-a456-426614174000") }
        assert_raises(Infra::Command::Invalid) { constructor.call("123e4567-e89b-42d3-7456-426614174000") }
      end
    end

    def test_rejects_invalid_order_and_product_ids
      assert_raises(Infra::Command::Invalid) { CreateDraftReturn.new(RETURN_ID, "bad", PRODUCTS) }
      assert_raises(Infra::Command::Invalid) { AddItemToReturn.new(RETURN_ID, "bad", PRODUCT_ID) }
      assert_raises(Infra::Command::Invalid) { AddItemToReturn.new(RETURN_ID, ORDER_ID, "bad") }
      assert_raises(Infra::Command::Invalid) { RemoveItemFromReturn.new(RETURN_ID, "bad", PRODUCT_ID) }
      assert_raises(Infra::Command::Invalid) { RemoveItemFromReturn.new(RETURN_ID, ORDER_ID, "bad") }
    end

    def test_rejects_invalid_returnable_products
      assert_raises(Infra::Command::Invalid) { CreateDraftReturn.new(RETURN_ID, ORDER_ID, Object.new) }
      assert_raises(Infra::Command::Invalid) { CreateDraftReturn.new(RETURN_ID, ORDER_ID, Class.new { def map = [] }.new) }
      hash_like = Class.new { def fetch(key) = { product_id: PRODUCT_ID, quantity: 2 }.fetch(key) }.new
      assert_raises(Infra::Command::Invalid) { CreateDraftReturn.new(RETURN_ID, ORDER_ID, [hash_like]) }
      assert_raises(Infra::Command::Invalid) { CreateDraftReturn.new(RETURN_ID, ORDER_ID, [{}]) }
      assert_raises(Infra::Command::Invalid) { CreateDraftReturn.new(RETURN_ID, ORDER_ID, [{ product_id: "bad", quantity: 1 }]) }
      assert_raises(Infra::Command::Invalid) { CreateDraftReturn.new(RETURN_ID, ORDER_ID, [{ product_id: PRODUCT_ID, quantity: "1" }]) }
      assert_raises(Infra::Command::Invalid) do
        CreateDraftReturn.new(RETURN_ID, ORDER_ID, [PRODUCTS.first, { product_id: "bad", quantity: 1 }])
      end
    end

    def test_accepts_array_and_hash_subclasses
      product = Class.new(Hash)[product_id: PRODUCT_ID, quantity: 2]
      products = Class.new(Array).new([product])
      assert_equal(PRODUCTS, CreateDraftReturn.new(RETURN_ID, ORDER_ID, products).returnable_products)
    end

    private

    def constructors
      [
        ->(id) { CreateDraftReturn.new(id, ORDER_ID, PRODUCTS) },
        ->(id) { AddItemToReturn.new(id, ORDER_ID, PRODUCT_ID) },
        ->(id) { RemoveItemFromReturn.new(id, ORDER_ID, PRODUCT_ID) }
      ]
    end
  end
end
