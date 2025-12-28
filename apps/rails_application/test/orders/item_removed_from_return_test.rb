require "test_helper"

module Returns
  class ItemRemovedFromReturnTest < InMemoryTestCase
    cover "Orders*"

    def test_remove_item_from_return
      return_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      another_product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      returnable_products = [{product_id: product_id, quantity: 1}, {product_id: another_product_id, quantity: 1}]
      create_draft_return(return_id, order_id, returnable_products)
      prepare_product(product_id, 50)
      prepare_product(another_product_id, 30)
      AddItemToReturn.new.call(item_added_to_return(return_id, order_id, product_id))
      AddItemToReturn.new.call(item_added_to_return(return_id, order_id, another_product_id))

      RemoveItemFromReturn.new.call(item_removed_from_return(return_id, order_id, product_id))

      assert_equal(1, Returns::ReturnItem.count)
      return_item = Returns::ReturnItem.find_by(return_uid: return_id, product_uid: another_product_id)
      assert_equal(another_product_id, return_item.product_uid)
      assert_equal(1, return_item.quantity)
      assert_equal(30, return_item.price)

      assert_equal(1, Returns::Return.count)
      return_record = Returns::Return.find_by(uid: return_id)
      assert_equal("Draft", return_record.status)
    end

    private

    def create_draft_return(return_id, order_id, returnable_products)
      draft_return_created = Ordering::DraftReturnCreated.new(data: { return_id: return_id, order_id: order_id, returnable_products: returnable_products })
      CreateDraftReturn.new.call(draft_return_created)
    end

    def prepare_product(product_id, price)
      event_store.publish(
        ProductCatalog::ProductRegistered.new(
          data: {
            product_id: product_id
          }
        )
      )
      event_store.publish(
        ProductCatalog::ProductNamed.new(
          data: {
            product_id: product_id,
            name: "Async Remote"
          }
        )
      )
      event_store.publish(Pricing::PriceSet.new(data: { product_id: product_id, price: price }))
    end

    def event_store
      Rails.configuration.event_store
    end

    def item_added_to_return(return_id, order_id, product_id)
      Ordering::ItemAddedToReturn.new(data: { return_id: return_id, order_id: order_id, product_id: product_id })
    end

    def item_removed_from_return(return_id, order_id, product_id)
      Ordering::ItemRemovedFromReturn.new(data: { return_id: return_id, order_id: order_id, product_id: product_id })
    end
  end
end
