module VatRates
  class RemoveAvailableVatRate
    def call(event)
      AvailableVatRate.destroy_by(code: event.data.fetch(:vat_rate_code))
    end
  end
end
