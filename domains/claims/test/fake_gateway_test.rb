require_relative "test_helper"

module Claims
  class FakeGatewayTest < Test
    cover "Claims::FakeGateway*"

    def test_records_paid_out_transactions
      gateway = FakeGateway.new
      claim_id = SecureRandom.uuid

      gateway.pay_out(claim_id, BigDecimal("300"))

      assert_equal([[claim_id, BigDecimal("300")]], gateway.paid_out_transactions)
    end

    def test_reset_clears_paid_out_transactions
      gateway = FakeGateway.new
      gateway.pay_out(SecureRandom.uuid, BigDecimal("300"))

      gateway.reset

      assert_equal([], gateway.paid_out_transactions)
    end
  end
end
