module Payments
  AlreadyAuthorized = Class.new(StandardError)

  class Payment
    include AggregateRoot

    def authorize(transaction_id, order_id)
      raise AlreadyAuthorized if authorized?
      apply(PaymentAuthorized.new(data: {
        transaction_id: transaction_id,
        order_id: order_id
      }))
    end

    private

    on PaymentAuthorized do |event|
      @state = :authorized
    end

    def authorized?
      @state == :authorized
    end
  end
end

