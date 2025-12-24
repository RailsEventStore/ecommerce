module VatRates
  class AvailableVatRate < ApplicationRecord
    self.table_name = "available_vat_rates"
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(AddAvailableVatRate, to: [Taxes::AvailableVatRateAdded])
      event_store.subscribe(RemoveAvailableVatRate, to: [Taxes::AvailableVatRateRemoved])
      event_store.subscribe(AssignStoreToAvailableVatRate.new, to: [Stores::VatRateRegistered])
    end
  end
end
