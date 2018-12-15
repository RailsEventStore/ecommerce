module Payments
  class OnAuthorizePayment
    include CommandHandler

    def call(command)
      payment = rehydrate(Payment.new, stream_name(Payment, command.transaction_id))
      payment.authorize(command.transaction_id, command.order_id)
      payment.store
    end
  end
end
