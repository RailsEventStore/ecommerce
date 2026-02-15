require "test_helper"

module VatRates
  class AssignStoreToAvailableVatRateTest < InMemoryTestCase
    cover "VatRates*"

    def configure(event_store, _command_bus)
      VatRates::Configuration.new.call(event_store)
    end

    def test_assign_store_to_available_vat_rate
      event_store = Rails.configuration.event_store
      store_id = SecureRandom.uuid
      vat_rate_id = SecureRandom.uuid

      event_store.publish(Taxes::AvailableVatRateAdded.new(data: { available_vat_rate_id: vat_rate_id, vat_rate: { code: "standard", rate: 20 } }))
      event_store.publish(Stores::VatRateRegistered.new(data: { store_id: store_id, vat_rate_id: vat_rate_id }))

      vat_rates = VatRates.available_vat_rates_for_store(store_id)
      assert_equal(1, vat_rates.count)
      assert_equal(store_id, vat_rates.first.store_id)
      assert_equal(vat_rate_id, vat_rates.first.uid)
    end

    def test_assign_store_to_existing_available_vat_rate
      event_store = Rails.configuration.event_store
      store_id = SecureRandom.uuid
      vat_rate_id = SecureRandom.uuid
      AvailableVatRate.create!(uid: vat_rate_id, code: "standard", rate: 20)

      event_store.publish(Stores::VatRateRegistered.new(data: { store_id: store_id, vat_rate_id: vat_rate_id }))

      vat_rates = VatRates.available_vat_rates_for_store(store_id)
      assert_equal(1, vat_rates.count)
      assert_equal(store_id, vat_rates.first.store_id)
    end

    def test_assigns_store_to_correct_vat_rate_by_uid
      event_store = Rails.configuration.event_store
      store_id = SecureRandom.uuid
      vat_rate_1_id = SecureRandom.uuid
      vat_rate_2_id = SecureRandom.uuid

      AvailableVatRate.create!(uid: vat_rate_1_id, code: "standard", rate: 20)
      AvailableVatRate.create!(uid: vat_rate_2_id, code: "reduced", rate: 10)

      event_store.publish(Stores::VatRateRegistered.new(data: { store_id: store_id, vat_rate_id: vat_rate_1_id }))

      vat_rates_for_store = VatRates.available_vat_rates_for_store(store_id)
      assert_equal(1, vat_rates_for_store.count)
      assert_equal(vat_rate_1_id, vat_rates_for_store.first.uid)
    end
  end
end
