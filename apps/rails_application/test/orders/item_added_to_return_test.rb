require "test_helper"

module Returns
  class ItemAddedToReturnTest < InMemoryTestCase
    cover "Orders*"

    def test_add_item_to_return
      return_id = SecureRandom.uuid
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid
      prepare_product(product_id, 50)
      place_order(order_id, product_id, 50)
      create_draft_return(return_id, order_id)

      AddItemToReturn.new.call(item_added_to_return(return_id, order_id, product_id))

      assert_equal(1, Returns::ReturnItem.count)
      return_item = Returns::ReturnItem.find_by(return_uid: return_id, product_uid: product_id)
      assert_equal(product_id, return_item.product_uid)
      assert_equal(1, return_item.quantity)
      assert_equal(50, return_item.price)

      assert_equal(1, Returns::Return.count)
      return_record = Returns::Return.find_by(uid: return_id)
      assert_equal("Draft", return_record.status)
    end

    private

    def event_store
      Rails.configuration.event_store
    end

    def prepare_product(product_id, price)
      vat_rate = Infra::Types::VatRate.new(rate: 20, code: "20")
      event_store.publish(
        ProductCatalog::ProductRegistered.new(
          data: { product_id: product_id }
        )
      )
      event_store.publish(
        ProductCatalog::ProductNamed.new(
          data: { product_id: product_id, name: "Async Remote" }
        )
      )
      event_store.publish(Pricing::PriceSet.new(data: { product_id: product_id, price: price }))
      event_store.publish(Taxes::VatRateSet.new(data: { product_id: product_id, vat_rate: vat_rate }))
    end

    def place_order(order_id, product_id, price)
      event_store.publish(
        Pricing::PriceItemAdded.new(
          data: {
            order_id: order_id,
            product_id: product_id,
            base_price: price,
            price: price,
            base_total_value: price,
            total_value: price
          }
        )
      )
      event_store.publish(
        Pricing::OfferAccepted.new(
          data: {
            order_id: order_id,
            order_lines: [{ product_id: product_id, quantity: 1 }]
          }
        )
      )
    end

    def create_draft_return(return_id, order_id)
      draft_return_created = Ordering::DraftReturnCreated.new(
        data: { return_id: return_id, order_id: order_id, returnable_products: [] }
      )
      CreateDraftReturn.new.call(draft_return_created)
    end

    def item_added_to_return(return_id, order_id, product_id)
      Ordering::ItemAddedToReturn.new(data: { return_id: return_id, order_id: order_id, product_id: product_id })
    end
  end
end
