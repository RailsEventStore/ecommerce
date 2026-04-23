require "test_helper"

module Returns
  class CreateDraftReturnTest < InMemoryTestCase
    cover "Returns::CreateDraftReturn*"

    def configure(event_store, _command_bus)
      Returns::Configuration.new.call(event_store)
    end

    def test_creates_draft_record_with_uid_order_uid_status_and_zero_total
      return_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      other_return_id = SecureRandom.uuid
      other_order_id = SecureRandom.uuid

      publish_draft(return_id, order_id)
      publish_draft(other_return_id, other_order_id)

      record = Return.find_by!(uid: return_id)
      assert_equal(return_id, record.uid)
      assert_equal(order_id, record.order_uid)
      assert_equal("Draft", record.status)
      assert_equal(0, record.total_value)
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
