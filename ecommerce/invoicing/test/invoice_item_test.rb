require_relative "test_helper"

module Invoicing
  class InvoiceItemTest < Test
    cover "Invoicing::Invoice"

    def test_initializer
      product_id = SecureRandom.uuid
      vat_rate = Infra::Types::VatRate.new(rate: 20, code: "20")
      unit_price = 100.to_d
      quantity = 20
      item = InvoiceItem.new(product_id, unit_price, vat_rate, quantity)

      assert_equal product_id, item.product_id
      assert_equal vat_rate, item.vat_rate
      assert_equal unit_price, item.unit_price
      assert_equal quantity, item.quantity
    end
  end
end