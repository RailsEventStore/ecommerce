require_relative "test_helper"

module Taxes
  class VatRateCatalogTest < Test
    class VatRateAvailableTest < VatRateCatalogTest
      def test_returns_true_when_vat_rate_is_available
        vat_rate = Infra::Types::VatRate.new(code: "50", rate: 50)
        add_available_vat_rate(vat_rate)

        assert catalog.vat_rate_available?(vat_rate.code)
      end

      def test_returns_false_when_vat_rate_is_not_available
        vat_rate = Infra::Types::VatRate.new(code: "50", rate: 50)

        refute catalog.vat_rate_available?(vat_rate.code)
      end

      def test_returns_false_when_vat_rate_is_not_available_even_when_other_vat_rates_are_available
        vat_rate = Infra::Types::VatRate.new(code: "50", rate: 50)
        add_available_vat_rate(vat_rate)

        refute catalog.vat_rate_available?("60")
      end
    end


    private

    def catalog
      VatRateCatalog.new(@event_store)
    end

    def add_available_vat_rate(vat_rate, available_vat_rate_id = SecureRandom.uuid)
      run_command(AddAvailableVatRate.new(available_vat_rate_id: available_vat_rate_id, vat_rate: vat_rate))
    end
  end
end
