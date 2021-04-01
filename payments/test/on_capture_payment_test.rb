require_relative 'test_helper'

module Payments
  class OnCapturePaymentTest < ActiveSupport::TestCase
    include TestPlumbing

    cover 'Payments::OnCapturePayment*'

    test 'capture payment' do
      transaction_id = SecureRandom.hex(16)
      order_id = SecureRandom.uuid
      stream = "Payments::Payment$#{transaction_id}"
      product  = ProductCatalog::Product.create(name: 'test')
      customer = Customer.create(name: 'test')
      arrange(
        Ordering::AddItemToBasket.new(order_id: order_id, product_id: product.id),
        Ordering::SubmitOrder.new(order_id: order_id, customer_id: customer.id),
        AuthorizePayment.new(transaction_id: transaction_id, order_id: order_id)
      )

      assert_events(
        stream,
        PaymentCaptured.new(
          data: {
            transaction_id: transaction_id,
            order_id: order_id
          }
        )
      ) do
        act(
          CapturePayment.new(transaction_id: transaction_id, order_id: order_id)
        )
      end
    end
  end
end
