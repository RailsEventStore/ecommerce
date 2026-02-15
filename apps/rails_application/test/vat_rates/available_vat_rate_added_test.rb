require "test_helper"

module VatRates
  class AvailableVatRateAddedTest < InMemoryTestCase
    cover "VatRates*"

    def configure(event_store, _command_bus)
      VatRates::Configuration.new.call(event_store)
    end

    def test_adding_available_vat_rate
      uid = SecureRandom.uuid
      code = "50"
      rate = 50

      event_store.publish(available_vat_rate_added_event(uid, code, rate))
      available_vat_rate = AvailableVatRate.find_by_uid(uid)

      assert_equal(uid, available_vat_rate.uid)
      assert_equal(code, available_vat_rate.code)
      assert_equal(rate, available_vat_rate.rate)
    end

    private

    def event_store
      Rails.configuration.event_store
    end

    def available_vat_rate_added_event(uid, code, rate)
      Taxes::AvailableVatRateAdded.new(
        data: {
          available_vat_rate_id: uid,
          vat_rate:
            {
              code: code,
              rate: rate
            }
          }
        )
    end
  end
end
