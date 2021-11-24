require_relative "test_helper"

module Invoicing
  class InvoicingTest < Test
    def test_generate_invoice
      assert true
    end

    def test_setting_available_vat_rate
      product_id = SecureRandom.uuid
      vat_rate_set = VatRateSet.new(data: { product_id: product_id, vat_rate: available_vat_rate })
      assert_events("Invoicing::Product$#{product_id}", vat_rate_set) do
        set_vat_rate(product_id, available_vat_rate)
      end
    end

    def test_setting_unavailable_vat_rate_should_raise_error
      product_id = SecureRandom.uuid
      assert_raises(Product::VatRateNotApplicable) do
        set_vat_rate(product_id, unavailable_vat_rate)
      end
    end

    private

    def set_vat_rate product_id, vat_rate
      run_command(SetVatRate.new(product_id: product_id, vat_rate: vat_rate))
    end

    def available_vat_rate
      Configuration.AVAILABLE_VAT_RATES.first
    end

    def unavailable_vat_rate
      Infra::Types::VatRate.new(code: "50", rate: 50)
    end
  end
end
