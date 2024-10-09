require_relative "test_helper"

module Taxes
  class VatRateCatalogTest < Test
    class VatRateByCodeTest < VatRateCatalogTest
      def setup
        @vat_rate = Infra::Types::VatRate.new(code: "50", rate: 50)
        add_available_vat_rate(@vat_rate)
      end

      def test_returns_available_vat_rate
        assert_equal @vat_rate, catalog.vat_rate_by_code("50")
      end

      def test_returns_nil_when_vat_rate_is_not_available
        assert_nil catalog.vat_rate_by_code("60")
      end

      def test_returns_nil_when_vat_rate_was_removed
        run_command(RemoveAvailableVatRate.new(vat_rate_code: "50"))

        assert_nil catalog.vat_rate_by_code("50")
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
