require_relative "test_helper"

module Taxes
  class TaxesTest < Test
    def test_setting_available_vat_rate
      product_id = SecureRandom.uuid
      vat_rate_set = VatRateSet.new(data: { product_id: product_id, vat_rate: available_vat_rate })
      assert_events("Taxes::Product$#{product_id}", vat_rate_set) do
        set_vat_rate(product_id, available_vat_rate)
      end
    end

    def test_setting_unavailable_vat_rate_should_raise_error
      product_id = SecureRandom.uuid
      assert_raises(Product::VatRateNotApplicable) do
        set_vat_rate(product_id, unavailable_vat_rate)
      end
    end

    def test_determining_vat_rate
      order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      another_product_id = SecureRandom.uuid

      set_vat_rate(product_id, available_vat_rate)
      vat_rate_determined = VatRateDetermined.new(data: { order_id: order_id, product_id: product_id, vat_rate: available_vat_rate })
      assert_events("Taxes::Order$#{order_id}", vat_rate_determined) do
        determine_vat_rate(order_id, product_id, available_vat_rate)
      end
      assert_events("Taxes::Order$#{order_id}") do
        determine_vat_rate(order_id, another_product_id, available_vat_rate)
      end
    end

    private

    def set_vat_rate(product_id, vat_rate)
      run_command(SetVatRate.new(product_id: product_id, vat_rate: vat_rate))
    end

    def determine_vat_rate(order_id, product_id, vat_rate)
      run_command(DetermineVatRate.new(order_id: order_id, product_id: product_id, vat_rate: vat_rate))
    end

    def available_vat_rate
      Configuration.available_vat_rates.first
    end

    def unavailable_vat_rate
      Infra::Types::VatRate.new(code: "50", rate: 50)
    end
  end
end
