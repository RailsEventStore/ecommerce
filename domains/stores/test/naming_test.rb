require_relative 'test_helper'
module Stores
  class NamingTest < Test
    cover "Stores*"

    def test_store_should_get_named
      uid = SecureRandom.uuid
      register_store(uid)
      assert name_store(uid, "Store 1")
    end

    def test_store_can_be_renamed
      uid = SecureRandom.uuid
      register_store(uid)
      assert name_store(uid, "Store 1")
      assert name_store(uid, "Store 2")
    end

    def test_should_publish_event
      uid = SecureRandom.uuid
      register_store(uid)
      store_named = Stores::StoreNamed.new(data: { store_id: uid, name: "Store 1" })
      assert_events("Stores::Store$#{uid}", store_named) do
        name_store(uid, "Store 1")
      end
    end

    private

    def register_store(uid)
      run_command(RegisterStore.new(store_id: uid))
    end

    def name_store(uid, name)
      run_command(NameStore.new(store_id: uid, name: StoreName.new(value: name)))
    end
  end
end
