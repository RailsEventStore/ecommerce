require_relative 'test_helper'

module Payments
  class OnReleasePaymentTest < ActiveSupport::TestCase
    include TestPlumbing

    cover 'Payments::OnReleasePayment*'

    test 'capture payment' do
      order_id = SecureRandom.uuid
      stream = "Payments::Payment$#{order_id}"

      product_uid = SecureRandom.uuid
      product_id = run_command(ProductCatalog::RegisterProduct.new(product_uid: product_uid, name: "test"))
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 20))
      customer = Customer.create(name: 'test')
      arrange(
        Pricing::AddItemToBasket.new(order_id: order_id, product_id: product_id),
        Ordering::SubmitOrder.new(order_id: order_id, customer_id: customer.id),
        AuthorizePayment.new(order_id: order_id)
      )

      assert_events(
        stream,
        PaymentReleased.new(
          data: {
            order_id: order_id
          }
        )
      ) do
        act(
          ReleasePayment.new(order_id: order_id)
        )
      end
    end
  end
end
