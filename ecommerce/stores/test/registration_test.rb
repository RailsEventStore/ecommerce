require_relative 'test_helper'
module Stores
  class RegistrationTest < Test
    cover "Stores*"

    def test_store_should_get_registered
      uid = SecureRandom.uuid
      assert register_store(uid)
    end

    def test_should_not_allow_for_double_registration
      uid = SecureRandom.uuid
      assert_raises(AlreadyRegistered) do
        register_store(uid)
        register_store(uid)
      end
    end

    def test_should_publish_event
      uid = SecureRandom.uuid
      store_registered = Stores::StoreRegistered.new(data: { store_id: uid })
      assert_events("Stores::Store$#{uid}", store_registered) do
        register_store(uid)
      end
    end

    def test_each_store_has_its_own_lifecycle
      store_1_id = SecureRandom.uuid
      store_1_registered = Stores::StoreRegistered.new(data: { store_id: store_1_id })
      store_2_id = SecureRandom.uuid
      store_2_registered = Stores::StoreRegistered.new(data: { store_id: store_2_id })

      assert_events("Stores::Store$#{store_1_id}", store_1_registered) do
        register_store(store_1_id)
      end

      assert_events("Stores::Store$#{store_2_id}", store_2_registered) do
        register_store(store_2_id)
      end
    end

    private

    def register_store(uid)
      run_command(RegisterStore.new(store_id: uid))
    end
  end
end
