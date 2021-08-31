require_relative 'test_helper'

module Payments
  class OnCapturePaymentTest < Ecommerce::InMemoryTestCase
    include TestPlumbing.with(
      event_store: ->{ Rails.configuration.event_store },
      command_bus: ->{ Rails.configuration.command_bus }
    )

    cover 'Payments::OnCapturePayment*'

    test 'capture payment' do
      order_id = SecureRandom.uuid
      stream = "Payments::Payment$#{order_id}"

      product_id = SecureRandom.uuid
      run_command(ProductCatalog::RegisterProduct.new(product_id: product_id, name: "test"))
      run_command(Pricing::SetPrice.new(product_id: product_id, price: 20))

      customer_id = SecureRandom.uuid
      run_command(Crm::RegisterCustomer.new(customer_id: customer_id, name: 'test'))
      Rails.configuration.payment_gateway.call.reset
      arrange(
        Pricing::AddItemToBasket.new(order_id: order_id, product_id: product_id),
        Ordering::SubmitOrder.new(order_id: order_id, customer_id: customer_id),
        AuthorizePayment.new(order_id: order_id)
      )
      assert_equal(20, Rails.configuration.payment_gateway.call.authorized_transactions[0][1])

      assert_events(
        stream,
        PaymentCaptured.new(
          data: {
            order_id: order_id
          }
        )
      ) do
        act(
          CapturePayment.new(order_id: order_id)
        )
      end
    end
  end
end
