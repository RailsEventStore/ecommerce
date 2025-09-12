module Ordering
  class ReturnableProducts
    def call(event_store, order_id)
      accepted_event = event_store
        .read.backward
        .stream("Pricing::Offer$#{order_id}")
        .of_type(Pricing::OfferAccepted)
        .first

      placed_event = event_store
        .read
        .stream("Fulfillment::Order$#{order_id}")
        .first

      accepted_event.data.fetch(:order_lines) if placed_event
    end
  end

  RefundableProducts = ReturnableProducts
end
