require_relative "test_helper"

module Invoicing
  class CommandsTest < Test
    cover "Invoicing*"

    ID = "123e4567-e89b-42d3-a456-426614174000"
    PRODUCT_ID = "223e4567-e89b-42d3-a456-426614174000"
    ADDRESS = { line_1: "1 Main St", line_2: "", line_3: "", line_4: "" }.freeze
    VAT_RATE = { code: "20", rate: 20 }.freeze

    def test_exposes_and_coerces_invoice_item_attributes
      command = AddInvoiceItem.new(ID, PRODUCT_ID, 2, "10.5", VAT_RATE)
      assert_equal(ID, command.invoice_id)
      assert_equal(PRODUCT_ID, command.product_id)
      assert_equal(2, command.quantity)
      assert_equal(BigDecimal("10.5"), command.unit_price)
      assert_equal(Infra::Types::VatRate.new(VAT_RATE), command.vat_rate)
    end

    def test_exposes_and_coerces_other_attributes
      date = Date.new(2026, 9, 21)
      assert_equal(date, IssueInvoice.new(ID, date).issue_date)
      assert_equal(date, SetPaymentDate.new(ID, date).payment_date)
      assert_nil(SetBillingAddress.new(ID, nil, ADDRESS).tax_id_number)
      assert_equal(Infra::Types::PostalAddress.new(ADDRESS), SetBillingAddress.new(ID, "VAT", ADDRESS).postal_address)
      assert_equal("Product", SetProductNameDisplayedOnInvoice.new(PRODUCT_ID, "Product").name_displayed)
    end

    def test_rejects_invalid_ids
      constructors.each do |constructor|
        assert_raises(Infra::Command::Invalid) { constructor.call("not-a-uuid") }
        assert_raises(Infra::Command::Invalid) { constructor.call(Object.new) }
        assert_raises(Infra::Command::Invalid) { constructor.call("123e4567-e89b-12d3-a456-426614174000") }
        assert_raises(Infra::Command::Invalid) { constructor.call("123e4567-e89b-42d3-7456-426614174000") }
      end
      assert_raises(Infra::Command::Invalid) { AddInvoiceItem.new(ID, "bad", 1, 10, VAT_RATE) }
    end

    def test_rejects_invalid_invoice_item_values
      assert_equal(BigDecimal("0"), AddInvoiceItem.new(ID, PRODUCT_ID, 1, 0, VAT_RATE).unit_price)
      assert_raises(Infra::Command::Invalid) { AddInvoiceItem.new(ID, PRODUCT_ID, 0, 10, VAT_RATE) }
      assert_raises(Infra::Command::Invalid) { AddInvoiceItem.new(ID, PRODUCT_ID, 1.0, 10, VAT_RATE) }
      assert_raises(Infra::Command::Invalid) { AddInvoiceItem.new(ID, PRODUCT_ID, 1, -1, VAT_RATE) }
      assert_raises(Infra::Command::Invalid) { AddInvoiceItem.new(ID, PRODUCT_ID, 1, Object.new, VAT_RATE) }
      assert_raises(Infra::Command::Invalid) { AddInvoiceItem.new(ID, PRODUCT_ID, 1, 10, Object.new) }
    end

    def test_rejects_invalid_dates_strings_and_address
      assert_raises(Infra::Command::Invalid) { IssueInvoice.new(ID, "2026-09-21") }
      assert_raises(Infra::Command::Invalid) { SetPaymentDate.new(ID, "2026-09-21") }
      assert_raises(Infra::Command::Invalid) { SetBillingAddress.new(ID, Object.new, ADDRESS) }
      assert_raises(Infra::Command::Invalid) { SetBillingAddress.new(ID, nil, Object.new) }
      assert_raises(Infra::Command::Invalid) { SetProductNameDisplayedOnInvoice.new(PRODUCT_ID, Object.new) }
    end

    def test_accepts_date_and_string_subclasses
      date = Class.new(Date).new(2026, 9, 21)
      string = Class.new(String).new("value")
      assert_equal(date, IssueInvoice.new(ID, date).issue_date)
      assert_equal(date, SetPaymentDate.new(ID, date).payment_date)
      assert_equal(string, SetBillingAddress.new(ID, string, ADDRESS).tax_id_number)
      assert_equal(string, SetProductNameDisplayedOnInvoice.new(PRODUCT_ID, string).name_displayed)
    end

    private

    def constructors
      date = Date.new(2026, 9, 21)
      [
        ->(id) { AddInvoiceItem.new(id, PRODUCT_ID, 1, 10, VAT_RATE) },
        ->(id) { IssueInvoice.new(id, date) },
        ->(id) { SetPaymentDate.new(id, date) },
        ->(id) { SetBillingAddress.new(id, nil, ADDRESS) },
        ->(id) { SetProductNameDisplayedOnInvoice.new(id, "Product") }
      ]
    end
  end
end
