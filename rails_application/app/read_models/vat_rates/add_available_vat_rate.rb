module VatRates
  class AddAvailableVatRate
    def call(event)
      AvailableVatRate.create!(
        uid: event.data.fetch(:available_vat_rate_id),
        code: event.data.fetch(:vat_rate).fetch(:code),
        rate: event.data.fetch(:vat_rate).fetch(:rate)
      )
    end
  end
end
