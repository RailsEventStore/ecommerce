module VatRates
  class AvailableVatRate < ApplicationRecord
    self.table_name = "available_vat_rates"

    def to_value
      Infra::Types::VatRate.new(code: code, rate: rate)
    end
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(AddAvailableVatRate, to: [Taxes::AvailableVatRateAdded])
    end
  end
end
