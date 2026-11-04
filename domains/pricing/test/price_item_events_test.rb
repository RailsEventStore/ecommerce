require_relative "test_helper"

module Pricing
  class PriceItemEventsTest < Test
    cover "Pricing*"

    def test_new_item_events_have_only_one_price
      data = { order_id: SecureRandom.uuid, product_id: SecureRandom.uuid, price: 37 }

      [PriceItemAdded, PriceItemRemoved].each do |event_class|
        assert_equal(data, event_class.new(data: data).data)
      end
    end
  end
end
