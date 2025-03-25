require_relative 'test_helper'

module Pricing
  class OfferLifecycleTest < Test
    cover "Pricing*"

    def test_accept_draft_offer
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      set_price(product_id, 33)
      add_item(order_id, product_id)
      stream = "Pricing::Offer$#{order_id}"

      assert_events(
        stream,
        OfferAccepted.new(
          data: {
            order_id: order_id,
            order_lines: [
              { product_id:, quantity: 1 },
            ]
          }
        )
      ) { accept_offer(order_id) }
    end

    def test_empty_offer_cant_be_accepted
      order_id = SecureRandom.uuid

      assert_raises(Pricing::Offer::IsEmpty) do
        accept_offer(order_id)
      end
    end

    def test_accepted_offer_can_be_rejected
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      set_price(product_id, 33)
      add_item(order_id, product_id)
      accept_offer(order_id)
      stream = "Pricing::Offer$#{order_id}"


      assert_events(
        stream,
        OfferRejected.new(
          data: {
            order_id: order_id,
          }
        )
      ) { reject_offer(order_id) }

    end

    def test_draft_offer_cant_be_rejected
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      set_price(product_id, 33)
      add_item(order_id, product_id)

      exp = assert_raises(Pricing::Offer::InvalidState, "Only accepted offer can be rejected") do
        reject_offer(order_id)
      end
      assert_equal("Only accepted offer can be rejected", exp.message)
    end

    def test_draft_offer_can_be_expired
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      set_price(product_id, 33)
      add_item(order_id, product_id)
      stream = "Pricing::Offer$#{order_id}"

      assert_events(
        stream,
        OfferExpired.new(
          data: {
            order_id: order_id,
          }
        )
      ) { expire_offer(order_id) }
    end

    def test_accepted_offer_cant_be_expired
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      set_price(product_id, 33)
      add_item(order_id, product_id)
      accept_offer(order_id)

      exp = assert_raises(Pricing::Offer::InvalidState) do
        expire_offer(order_id)
      end
      assert_equal("Only draft offer can be expired", exp.message)
    end

    def test_only_draft_offer_can_be_accepted
      product_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      set_price(product_id, 33)
      add_item(order_id, product_id)
      accept_offer(order_id)

      exp = assert_raises(Pricing::Offer::InvalidState) do
        accept_offer(order_id)
      end
      assert_equal("Only draft offer can be accepted", exp.message)
    end

    private

    def accept_offer(order_id)
      run_command(AcceptOffer.new(order_id:))
    end

    def reject_offer(order_id)
      run_command(RejectOffer.new(order_id:))
    end

    def expire_offer(order_id)
      run_command(ExpireOffer.new(order_id:))
    end
  end
end
