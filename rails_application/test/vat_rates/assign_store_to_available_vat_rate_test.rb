require "test_helper"

module VatRates
  class AssignStoreToAvailableVatRateTest < InMemoryRESIntegrationTestCase
    cover "VatRates*"

    def test_assign_store_to_available_vat_rate
      event_store = Rails.configuration.event_store
      store_id = SecureRandom.uuid
      vat_rate_id = SecureRandom.uuid

      event_store.publish(Taxes::AvailableVatRateAdded.new(data: { available_vat_rate_id: vat_rate_id, vat_rate: { code: "standard", rate: 20 } }))
      event_store.publish(Stores::VatRateRegistered.new(data: { store_id: store_id, vat_rate_id: vat_rate_id }))

      assert_equal(store_id, AvailableVatRate.find_by!(uid: vat_rate_id).store_id)
    end

    def test_assign_store_to_existing_available_vat_rate
      event_store = Rails.configuration.event_store
      store_id = SecureRandom.uuid
      vat_rate_id = SecureRandom.uuid
      AvailableVatRate.create!(uid: vat_rate_id, code: "standard", rate: 20)

      event_store.publish(Stores::VatRateRegistered.new(data: { store_id: store_id, vat_rate_id: vat_rate_id }))

      assert_equal(store_id, AvailableVatRate.find_by!(uid: vat_rate_id).store_id)
    end
  end
end
