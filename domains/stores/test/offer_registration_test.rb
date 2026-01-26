require_relative 'test_helper'
module Stores
  class OfferRegistrationTest < Test
    cover "Stores*"

    def test_offer_should_get_registered
      store_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      assert(register_offer(store_id, order_id))
    end

    def test_should_publish_event
      store_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      offer_registered = Stores::OfferRegistered.new(data: { store_id: store_id, order_id: order_id })
      assert_events("Stores::Store$#{store_id}", offer_registered) do
        register_offer(store_id, order_id)
      end
    end

    private

    def register_offer(store_id, order_id)
      run_command(RegisterOffer.new(store_id: store_id, order_id: order_id))
    end
  end
end
