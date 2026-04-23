require "test_helper"

module Returns
  class RemoveItemFromReturnTest < InMemoryTestCase
    cover "Returns::RemoveItemFromReturn*"

    def configure(event_store, _command_bus)
      Returns::Configuration.new.call(event_store)
      Orders::Configuration.new.call(event_store)
    end

    def test_remove_decrements_quantity_and_total_when_quantity_stays_positive
      return_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      product_id = register_product("Ruby Book", 42)
      publish_draft(return_id, order_id)
      publish_add(return_id, order_id, product_id)
      publish_add(return_id, order_id, product_id)

      publish_remove(return_id, order_id, product_id)

      return_record = Return.find_by!(uid: return_id)
      item = return_record.return_items.find_by!(product_uid: product_id)
      assert_equal(1, item.quantity)
      assert_equal(42, return_record.total_value)
    end

    def test_remove_destroys_item_when_quantity_drops_to_zero
      return_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      product_id = register_product("Ruby Book", 42)
      publish_draft(return_id, order_id)
      publish_add(return_id, order_id, product_id)

      publish_remove(return_id, order_id, product_id)

      return_record = Return.find_by!(uid: return_id)
      assert_nil(return_record.return_items.find_by(product_uid: product_id))
      assert_equal(0, return_record.total_value)
    end

    def test_remove_only_mutates_matching_return
      return_id = SecureRandom.uuid
      untouched_return_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      product_id = register_product("Ruby Book", 42)
      publish_draft(return_id, order_id)
      publish_draft(untouched_return_id, order_id)
      publish_add(return_id, order_id, product_id)
      publish_add(untouched_return_id, order_id, product_id)

      publish_remove(return_id, order_id, product_id)

      assert_equal(42, Return.find_by!(uid: untouched_return_id).total_value)
      assert_equal(1, Return.find_by!(uid: untouched_return_id).return_items.find_by!(product_uid: product_id).quantity)
    end

    def test_remove_only_mutates_matching_product
      return_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      removed_product_id = register_product("Ruby Book", 42)
      other_product_id = register_product("Rails Book", 99)
      publish_draft(return_id, order_id)
      publish_add(return_id, order_id, removed_product_id)
      publish_add(return_id, order_id, removed_product_id)
      publish_add(return_id, order_id, other_product_id)

      publish_remove(return_id, order_id, removed_product_id)

      return_record = Return.find_by!(uid: return_id)
      assert_equal(1, return_record.return_items.find_by!(product_uid: removed_product_id).quantity)
      assert_equal(1, return_record.return_items.find_by!(product_uid: other_product_id).quantity)
    end

    private

    def register_product(name, price)
      product_id = SecureRandom.uuid
      event_store.publish(ProductCatalog::ProductRegistered.new(data: { product_id: product_id }))
      event_store.publish(ProductCatalog::ProductNamed.new(data: { product_id: product_id, name: name }))
      event_store.publish(Pricing::PriceSet.new(data: { product_id: product_id, price: price }))
      product_id
    end

    def publish_draft(return_id, order_id)
      event_store.publish(
        Ordering::DraftReturnCreated.new(
          data: { return_id: return_id, order_id: order_id, returnable_products: [] }
        )
      )
    end

    def publish_add(return_id, order_id, product_id)
      event_store.publish(
        Ordering::ItemAddedToReturn.new(
          data: { return_id: return_id, order_id: order_id, product_id: product_id }
        )
      )
    end

    def publish_remove(return_id, order_id, product_id)
      event_store.publish(
        Ordering::ItemRemovedFromReturn.new(
          data: { return_id: return_id, order_id: order_id, product_id: product_id }
        )
      )
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
