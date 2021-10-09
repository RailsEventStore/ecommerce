require_relative "test_helper"

module Shipping
  class PostalAddressTest < Test
    cover "Shipping::PostalAddress*"

    def test_initialize
      address = PostalAddress.new(
        line_1: "Mme Anna Kowalska",
        line_2: "Ul. Bosmanska 1",
        line_3: "81-116 GDYNIA",
        line_4: "POLAND"
      )

      assert_equal "Mme Anna Kowalska", address.line_1
      assert_equal "Ul. Bosmanska 1", address.line_2
      assert_equal "81-116 GDYNIA", address.line_3
      assert_equal "POLAND", address.line_4
    end

    private

    def order_id
      @order_id ||= SecureRandom.uuid
    end
  end
end
