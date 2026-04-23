require "test_helper"

module Returns
  class SetOrderNumberTest < InMemoryTestCase
    cover "Returns::SetOrderNumber*"

    def configure(event_store, _command_bus)
      Returns::Configuration.new.call(event_store)
    end

    def test_sets_order_number_on_all_returns_with_matching_order_uid
      order_id = SecureRandom.uuid
      other_order_id = SecureRandom.uuid
      return_1 = SecureRandom.uuid
      return_2 = SecureRandom.uuid
      return_other = SecureRandom.uuid

      publish_draft(return_1, order_id)
      publish_draft(return_2, order_id)
      publish_draft(return_other, other_order_id)

      event_store.publish(
        Fulfillment::OrderRegistered.new(data: { order_id: order_id, order_number: "2026/04/1" })
      )

      assert_equal("2026/04/1", Return.find_by!(uid: return_1).order_number)
      assert_equal("2026/04/1", Return.find_by!(uid: return_2).order_number)
      assert_nil(Return.find_by!(uid: return_other).order_number)
    end

    private

    def publish_draft(return_id, order_id)
      event_store.publish(
        Ordering::DraftReturnCreated.new(
          data: { return_id: return_id, order_id: order_id, returnable_products: [] }
        )
      )
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
