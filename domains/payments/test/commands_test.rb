require_relative "test_helper"

module Payments
  class CommandsTest < Test
    cover "Payments*"

    ORDER_ID = "123e4567-e89b-42d3-a456-426614174000"

    def test_exposes_attributes
      command = SetPaymentAmount.new(ORDER_ID, 20)

      assert_equal(ORDER_ID, command.order_id)
      assert_equal(20, command.amount)
      assert_equal(ORDER_ID, AuthorizePayment.new(ORDER_ID).order_id)
      assert_equal(ORDER_ID, CapturePayment.new(ORDER_ID).order_id)
      assert_equal(ORDER_ID, ReleasePayment.new(ORDER_ID).order_id)
    end

    def test_preserves_amount_without_coercion_or_validation
      amount = Object.new

      assert_same(amount, SetPaymentAmount.new(ORDER_ID, amount).amount)
    end

    def test_rejects_invalid_order_id
      order_id_constructors.each do |constructor|
        assert_raises(Infra::Command::Invalid) { constructor.call("not-a-uuid") }
        assert_raises(Infra::Command::Invalid) { constructor.call(Object.new) }
        assert_raises(Infra::Command::Invalid) { constructor.call("123e4567-e89b-12d3-a456-426614174000") }
        assert_raises(Infra::Command::Invalid) { constructor.call("123e4567-e89b-42d3-7456-426614174000") }
      end
    end

    private

    def order_id_constructors
      [
        ->(order_id) { SetPaymentAmount.new(order_id, 20) },
        ->(order_id) { AuthorizePayment.new(order_id) },
        ->(order_id) { CapturePayment.new(order_id) },
        ->(order_id) { ReleasePayment.new(order_id) }
      ]
    end
  end
end
