require_relative "test_helper"

module Payments
  class FakeGatewayTest < Test
    cover "Payments::FakeGateway*"

    def test_happy_path
      gateway = FakeGateway.new
      gateway.authorize_transaction("12", 20)
      assert_equal([["12", 20]], gateway.authorized_transactions)
      gateway.reset
      assert_equal([], gateway.authorized_transactions)
    end
  end
end
