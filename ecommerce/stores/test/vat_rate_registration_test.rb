require_relative 'test_helper'
module Stores
  class VatRateRegistrationTest < Test
    cover "Stores*"

    def test_vat_rate_should_get_registered
      store_id = SecureRandom.uuid
      vat_rate_id = SecureRandom.uuid
      assert register_vat_rate(store_id, vat_rate_id)
    end

    def test_should_publish_event
      store_id = SecureRandom.uuid
      vat_rate_id = SecureRandom.uuid
      vat_rate_registered = Stores::VatRateRegistered.new(data: { store_id: store_id, vat_rate_id: vat_rate_id })
      assert_events("Stores::Store$#{store_id}", vat_rate_registered) do
        register_vat_rate(store_id, vat_rate_id)
      end
    end

    private

    def register_vat_rate(store_id, vat_rate_id)
      run_command(RegisterVatRate.new(store_id: store_id, vat_rate_id: vat_rate_id))
    end
  end
end
