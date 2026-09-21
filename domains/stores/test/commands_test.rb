require_relative "test_helper"

module Stores
  class CommandsTest < Test
    cover "Stores*"

    STORE_ID = "123e4567-e89b-42d3-a456-426614174000"
    ENTITY_ID = "223e4567-e89b-42d3-a456-426614174000"

    def test_exposes_attributes
      assert_equal(STORE_ID, RegisterStore.new(STORE_ID).store_id)
      name = StoreName.new(value: "Store")
      assert_equal(name, NameStore.new(STORE_ID, name).name)
      assert_attributes(RegisterProduct.new(STORE_ID, ENTITY_ID), :product_id)
      assert_attributes(RegisterCustomer.new(STORE_ID, ENTITY_ID), :customer_id)
      assert_attributes(RegisterOffer.new(STORE_ID, ENTITY_ID), :order_id)
      assert_attributes(RegisterTimePromotion.new(STORE_ID, ENTITY_ID), :time_promotion_id)
      assert_attributes(RegisterCoupon.new(STORE_ID, ENTITY_ID), :coupon_id)
      assert_attributes(RegisterInvoice.new(STORE_ID, ENTITY_ID), :invoice_id)
      assert_attributes(RegisterShipment.new(STORE_ID, ENTITY_ID), :shipment_id)
      assert_attributes(RegisterVatRate.new(STORE_ID, ENTITY_ID), :vat_rate_id)
    end

    def test_rejects_invalid_store_ids
      constructors.each do |constructor|
        assert_raises(Infra::Command::Invalid) { constructor.call("not-a-uuid") }
        assert_raises(Infra::Command::Invalid) { constructor.call(Object.new) }
        assert_raises(Infra::Command::Invalid) { constructor.call("123e4567-e89b-12d3-a456-426614174000") }
        assert_raises(Infra::Command::Invalid) { constructor.call("123e4567-e89b-42d3-7456-426614174000") }
      end
    end

    def test_rejects_invalid_entity_ids
      entity_constructors.each do |constructor|
        assert_raises(Infra::Command::Invalid) { constructor.call("not-a-uuid") }
        assert_raises(Infra::Command::Invalid) { constructor.call(Object.new) }
        assert_raises(Infra::Command::Invalid) { constructor.call("123e4567-e89b-12d3-a456-426614174000") }
        assert_raises(Infra::Command::Invalid) { constructor.call("123e4567-e89b-42d3-7456-426614174000") }
      end
    end

    def test_requires_store_name
      assert_raises(Infra::Command::Invalid) { NameStore.new(STORE_ID, "Store") }
      name = Class.new(StoreName).new(value: "Store")
      assert_equal(name, NameStore.new(STORE_ID, name).name)
    end

    private

    def assert_attributes(command, attribute)
      assert_equal(STORE_ID, command.store_id)
      assert_equal(ENTITY_ID, command.public_send(attribute))
    end

    def constructors
      [
        ->(id) { RegisterStore.new(id) },
        ->(id) { NameStore.new(id, StoreName.new(value: "Store")) },
        *entity_constructors.map { |constructor| ->(id) { constructor.call(ENTITY_ID, id) } }
      ]
    end

    def entity_constructors
      [
        ->(id, store_id = STORE_ID) { RegisterProduct.new(store_id, id) },
        ->(id, store_id = STORE_ID) { RegisterCustomer.new(store_id, id) },
        ->(id, store_id = STORE_ID) { RegisterOffer.new(store_id, id) },
        ->(id, store_id = STORE_ID) { RegisterTimePromotion.new(store_id, id) },
        ->(id, store_id = STORE_ID) { RegisterCoupon.new(store_id, id) },
        ->(id, store_id = STORE_ID) { RegisterInvoice.new(store_id, id) },
        ->(id, store_id = STORE_ID) { RegisterShipment.new(store_id, id) },
        ->(id, store_id = STORE_ID) { RegisterVatRate.new(store_id, id) }
      ]
    end
  end
end
