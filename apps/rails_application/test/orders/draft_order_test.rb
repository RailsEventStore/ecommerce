require "test_helper"

module Orders
  class DraftOrderTest < InMemoryTestCase
    cover "Orders*"

    def test_order_is_created_when_offer_drafted
      event_store.publish(offer_drafted)

      order = Order.find_by(uid: order_id)
      assert(order)
      assert_equal("Draft", order.state)
    end

    private

    def event_store
      Rails.configuration.event_store
    end

    def order_id
      @order_id ||= SecureRandom.uuid
    end

    def offer_drafted
      Pricing::OfferDrafted.new(data: { order_id: order_id })
    end
  end
end
