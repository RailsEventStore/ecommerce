require "test_helper"

module VatRates
  class RemoveAvailableVatRateTest < InMemoryTestCase
    cover "VatRates*"

    def configure(event_store, _command_bus)
      VatRates::Configuration.new.call(event_store)
    end

    def test_removing_available_vat_rate
      uid = SecureRandom.uuid
      code = "standard"
      rate = 20

      event_store.publish(Taxes::AvailableVatRateAdded.new(data: { available_vat_rate_id: uid, vat_rate: { code: code, rate: rate } }))
      event_store.publish(Taxes::AvailableVatRateRemoved.new(data: { vat_rate_code: code }))

      assert_nil(AvailableVatRate.find_by(code: code))
    end

    private

    def event_store
      Rails.configuration.event_store
    end
  end
end
