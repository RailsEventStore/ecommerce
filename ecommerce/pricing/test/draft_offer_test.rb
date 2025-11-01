require_relative "test_helper"

module Pricing
  class DraftOfferTest < Test
    cover "Pricing*"

    def test_draft_offer
      order_id = SecureRandom.uuid
      stream = "Pricing::Offer$#{order_id}"

      assert_events(
        stream,
        OfferDrafted.new(data: { order_id: order_id })
      ) { draft_offer(order_id) }
    end

    private

    def draft_offer(order_id)
      run_command(DraftOffer.new(order_id: order_id))
    end
  end
end
