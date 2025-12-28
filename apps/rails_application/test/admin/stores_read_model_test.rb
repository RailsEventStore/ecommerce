require "test_helper"

class AdminStoresReadModelTest < InMemoryTestCase
  cover "Admin::RegisterStore*"
  cover "Admin::NameStore*"

  def test_register_store_creates_record
    previous_count = Admin::Store.count
    event_store.publish(store_registered)
    assert_equal(previous_count + 1, Admin::Store.count)
    assert Admin::Store.exists?(store_id)
  end

  def test_name_store_updates_name
    event_store.publish(store_registered)

    event_store.publish(store_named("Store 1"))

    assert_equal("Store 1", Admin::Store.find(store_id).name)
  end

  def test_name_store_can_rename
    event_store.publish(store_registered)

    event_store.publish(store_named("Store 1"))
    event_store.publish(store_named("Store 2"))

    assert_equal("Store 2", Admin::Store.find(store_id).name)
  end

  def test_name_store_updates_correct_store
    store1_id = SecureRandom.uuid
    store2_id = SecureRandom.uuid

    event_store.publish(Stores::StoreRegistered.new(data: { store_id: store1_id }))
    event_store.publish(Stores::StoreRegistered.new(data: { store_id: store2_id }))

    event_store.publish(Stores::StoreNamed.new(data: { store_id: store1_id, name: "Store 1" }))
    event_store.publish(Stores::StoreNamed.new(data: { store_id: store2_id, name: "Store 2" }))

    assert_equal("Store 1", Admin::Store.find(store1_id).name)
    assert_equal("Store 2", Admin::Store.find(store2_id).name)
  end

  private

  def store_id
    @store_id ||= SecureRandom.uuid
  end

  def store_registered
    Stores::StoreRegistered.new(data: { store_id: store_id })
  end

  def store_named(name)
    Stores::StoreNamed.new(data: { store_id: store_id, name: name })
  end

  def event_store
    Rails.configuration.event_store
  end
end
