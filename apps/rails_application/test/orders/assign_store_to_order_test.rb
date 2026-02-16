require "test_helper"

module Orders
  class AssignStoreToOrderTest < InMemoryTestCase
    cover "Orders*"

    def configure(event_store, _command_bus)
      Orders::Configuration.new.call(event_store)
    end

    def test_store_id_is_set_when_offer_registered_in_store
      other_order_id = SecureRandom.uuid
      event_store.publish(Pricing::OfferDrafted.new(data: { order_id: other_order_id }))
      event_store.publish(offer_drafted)
      event_store.publish(offer_registered_in_store)

      assert_equal(order_id, Orders.find_order_in_store(order_id, store_id).uid)
      assert_equal(store_id, Orders.store_id_for_order(order_id))
      assert_nil(Orders.find_order_in_store(other_order_id, store_id))
    end

    def test_store_id_is_updated_when_offer_registered_in_different_store
      store_2_id = SecureRandom.uuid

      event_store.publish(offer_drafted)
      event_store.publish(offer_registered_in_store)

      assert_equal(store_id, Order.find_by(uid: order_id).store_id)

      event_store.publish(offer_registered_in_different_store(store_2_id))

      assert_equal(store_2_id, Order.find_by(uid: order_id).store_id)
    end

    private

    def event_store
      Rails.configuration.event_store
    end

    def order_id
      @order_id ||= SecureRandom.uuid
    end

    def store_id
      @store_id ||= SecureRandom.uuid
    end

    def offer_drafted
      Pricing::OfferDrafted.new(data: { order_id: order_id })
    end

    def offer_registered_in_store
      Stores::OfferRegistered.new(data: { order_id: order_id, store_id: store_id })
    end

    def offer_registered_in_different_store(different_store_id)
      Stores::OfferRegistered.new(data: { order_id: order_id, store_id: different_store_id })
    end
  end
end
