module VatRates
  class AssignStoreToAvailableVatRate
    def call(event)
      AvailableVatRate.find_by!(uid: event.data.fetch(:vat_rate_id)).update!(store_id: event.data.fetch(:store_id))
    end
  end
end
