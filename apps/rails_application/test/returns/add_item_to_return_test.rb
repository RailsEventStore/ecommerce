require "test_helper"

module Returns
  class AddItemToReturnTest < InMemoryTestCase
    cover "Returns::AddItemToReturn*"

    def configure(event_store, _command_bus)
      Returns::Configuration.new.call(event_store)
      Orders::Configuration.new.call(event_store)
    end

    def test_first_add_creates_return_item_with_product_price_and_quantity_one
      return_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      product_id = register_product("Ruby Book", 42)
      publish_draft(return_id, order_id)

      publish_add(return_id, order_id, product_id)

      item = Return.find_by!(uid: return_id).return_items.find_by!(product_uid: product_id)
      assert_equal(1, item.quantity)
      assert_equal(42, item.price)
    end

    def test_second_add_increments_quantity_and_total_without_changing_price
      return_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      product_id = register_product("Ruby Book", 42)
      publish_draft(return_id, order_id)

      publish_add(return_id, order_id, product_id)
      publish_add(return_id, order_id, product_id)

      return_record = Return.find_by!(uid: return_id)
      item = return_record.return_items.find_by!(product_uid: product_id)
      assert_equal(2, item.quantity)
      assert_equal(42, item.price)
      assert_equal(84, return_record.total_value)
    end

    def test_add_only_mutates_matching_return
      return_id = SecureRandom.uuid
      untouched_return_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      product_id = register_product("Ruby Book", 42)
      publish_draft(return_id, order_id)
      publish_draft(untouched_return_id, order_id)

      publish_add(return_id, order_id, product_id)

      assert_equal(0, Return.find_by!(uid: untouched_return_id).total_value)
      assert_empty(Return.find_by!(uid: untouched_return_id).return_items)
    end

    def test_add_only_mutates_matching_product
      return_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      added_product_id = register_product("Ruby Book", 42)
      other_product_id = register_product("Rails Book", 99)
      publish_draft(return_id, order_id)

      publish_add(return_id, order_id, added_product_id)

      items = Return.find_by!(uid: return_id).return_items
      assert_equal(1, items.count)
      assert_equal(added_product_id, items.first.product_uid)
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

    def event_store
      Rails.configuration.event_store
    end
  end
end
