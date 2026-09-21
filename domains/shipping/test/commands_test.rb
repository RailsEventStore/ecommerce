require_relative "test_helper"

module Shipping
  class CommandsTest < Test
    cover "Shipping*"

    ORDER_ID = "123e4567-e89b-42d3-a456-426614174000"
    PRODUCT_ID = "223e4567-e89b-42d3-a456-426614174000"
    ADDRESS = { line_1: "1 Main St", line_2: "", line_3: "", line_4: "" }.freeze

    def test_exposes_attributes
      command = AddItemToShipmentPickingList.new(ORDER_ID, PRODUCT_ID)
      assert_equal(ORDER_ID, command.order_id)
      assert_equal(PRODUCT_ID, command.product_id)
      assert_equal(ORDER_ID, command.aggregate_id)
      assert_equal(ORDER_ID, SubmitShipment.new(ORDER_ID).order_id)
      assert_equal(ORDER_ID, AuthorizeShipment.new(ORDER_ID).order_id)
    end

    def test_coerces_postal_address_hash
      command = AddShippingAddressToShipment.new(ORDER_ID, ADDRESS)
      assert_equal(Infra::Types::PostalAddress.new(ADDRESS), command.postal_address)
    end

    def test_rejects_invalid_order_id
      constructors.each do |constructor|
        assert_raises(Infra::Command::Invalid) { constructor.call("not-a-uuid") }
        assert_raises(Infra::Command::Invalid) { constructor.call(Object.new) }
        assert_raises(Infra::Command::Invalid) { constructor.call("123e4567-e89b-12d3-a456-426614174000") }
        assert_raises(Infra::Command::Invalid) { constructor.call("123e4567-e89b-42d3-7456-426614174000") }
      end
    end

    def test_rejects_invalid_product_ids_and_addresses
      assert_raises(Infra::Command::Invalid) { AddItemToShipmentPickingList.new(ORDER_ID, "bad") }
      assert_raises(Infra::Command::Invalid) { RemoveItemFromShipmentPickingList.new(ORDER_ID, "bad") }
      assert_raises(Infra::Command::Invalid) { AddShippingAddressToShipment.new(ORDER_ID, Object.new) }
    end

    private

    def constructors
      [
        ->(id) { AddItemToShipmentPickingList.new(id, PRODUCT_ID) },
        ->(id) { RemoveItemFromShipmentPickingList.new(id, PRODUCT_ID) },
        ->(id) { AddShippingAddressToShipment.new(id, ADDRESS) },
        ->(id) { SubmitShipment.new(id) },
        ->(id) { AuthorizeShipment.new(id) }
      ]
    end
  end
end
