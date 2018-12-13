module Payments
  class Payment
    include AggregateRoot

    def authorize(transaction_id, order_id)
      apply(PaymentAuthorized.new(data: {
        transaction_id: transaction_id,
        order_id: order_id
      }))
    end

    private

    on PaymentAuthorized do |event|
    end
  end
end

