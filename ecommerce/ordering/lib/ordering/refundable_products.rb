module Ordering
  class RefundableProducts
    def call(event_store, order_id)
      event_store
        .read.backward
        .stream("Pricing::Offer$#{order_id}")
        .of_type(Pricing::OfferAccepted)
        .first
        &.data
        &.fetch(:order_lines) || []
    end
  end
end
