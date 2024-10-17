require_relative "test_helper"

module Taxes
  class TaxesTest < Test
    def test_setting_available_vat_rate
      vat_rate = Infra::Types::VatRate.new(code: "50", rate: 50)
      add_available_vat_rate(vat_rate)

      product_id = SecureRandom.uuid
      vat_rate_set = VatRateSet.new(data: { product_id: product_id, vat_rate: vat_rate })
      assert_events("Taxes::Product$#{product_id}", vat_rate_set) do
        set_vat_rate(product_id, vat_rate.code)
      end
    end

    def test_setting_unavailable_vat_rate_should_raise_error
      product_id = SecureRandom.uuid
      unavailable_vat_rate = Infra::Types::VatRate.new(code: "20", rate: 20)

      assert_raises(Taxes::VatRateNotApplicable) do
        set_vat_rate(product_id, unavailable_vat_rate.code)
      end
    end

    def test_determining_vat_rate
      vat_rate = Infra::Types::VatRate.new(code: "50", rate: 50)
      add_available_vat_rate(vat_rate)

      order_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      another_product_id = SecureRandom.uuid

      set_vat_rate(product_id, vat_rate.code)
      vat_rate_determined = VatRateDetermined.new(data: { order_id: order_id, product_id: product_id, vat_rate: vat_rate })
      assert_events("Taxes::Order$#{order_id}", vat_rate_determined) do
        determine_vat_rate(order_id, product_id, vat_rate)
      end
      assert_events("Taxes::Order$#{order_id}") do
        determine_vat_rate(order_id, another_product_id, vat_rate)
      end
    end

    def test_adding_available_vat_rate
      available_vat_rate_id = SecureRandom.uuid
      vat_rate = Infra::Types::VatRate.new(code: "50", rate: 50)
      available_vat_rate_added = AvailableVatRateAdded.new(data: { available_vat_rate_id: available_vat_rate_id, vat_rate: vat_rate })

      assert_events("Taxes::AvailableVatRate$#{vat_rate.code}", available_vat_rate_added) do
        add_available_vat_rate(vat_rate, available_vat_rate_id)
      end
    end

    def test_should_not_allow_for_double_registration
      vat_rate = Infra::Types::VatRate.new(code: "50", rate: 50)
      add_available_vat_rate(vat_rate)

      assert_raises(VatRateAlreadyExists) do
        add_available_vat_rate(vat_rate)
      end
    end

    def test_removing_available_vat_rate
      vat_rate = Infra::Types::VatRate.new(code: "50", rate: 50)
      add_available_vat_rate(vat_rate)
      available_vat_rate_removed = AvailableVatRateRemoved.new(data: { vat_rate_code: vat_rate.code })

      assert_events("Taxes::AvailableVatRate$#{vat_rate.code}", available_vat_rate_removed) do
        remove_available_vat_rate(vat_rate.code)
      end
    end

    def test_cannot_remove_non_existing_vat_rate
      assert_raises(VatRateNotExists) do
        remove_available_vat_rate("50")
      end
    end

    private

    def set_vat_rate(product_id, vat_rate_code)
      run_command(SetVatRate.new(product_id: product_id, vat_rate_code: vat_rate_code))
    end

    def determine_vat_rate(order_id, product_id, vat_rate)
      run_command(DetermineVatRate.new(order_id: order_id, product_id: product_id, vat_rate: vat_rate))
    end

    def add_available_vat_rate(vat_rate, available_vat_rate_id = SecureRandom.uuid)
      run_command(AddAvailableVatRate.new(available_vat_rate_id: available_vat_rate_id, vat_rate: vat_rate))
    end

    def remove_available_vat_rate(vat_rate_code)
      run_command(RemoveAvailableVatRate.new(vat_rate_code: vat_rate_code))
    end
  end
end
