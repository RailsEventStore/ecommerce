require_relative "test_helper"

module Payments
  class OnSetPaymentAmountTest < Test
    cover "Payments::OnSetPaymentAmount*"

    def test_registering_payment_intent
      order_id = SecureRandom.uuid
      amount = 20
      intent_id = "pi_1F5QxUC9bKSp3hWJgGrHksGL"
      stream = "Payments::Payment$#{order_id}"

      stub_create = stub_creating_payment_intent(payment_intent_json(intent_id, amount))

      assert_events(
        stream,
        PaymentIntentRegistered.new(data: { order_id: order_id, intent_id: intent_id }),
        PaymentAmountSet.new(data: { order_id: order_id, amount: amount })
      ) { act(SetPaymentAmount.new(order_id: order_id, amount: amount)) }
      assert_requested(stub_create)
    end

    def test_updating_payment_intent
      order_id = SecureRandom.uuid
      amount = 20
      intent_id = "pi_1F5QxUC9bKSp3hWJgGrHksGL"
      stream = "Payments::Payment$#{order_id}"
      stub_creating_payment_intent(payment_intent_json(intent_id, amount))
      stub_update = stub_updating_payment_intent(intent_id, payment_intent_json(intent_id, amount))

      arrange(SetPaymentAmount.new(order_id: order_id, amount: amount))

      assert_events(
        stream,
        PaymentAmountSet.new(data: { order_id: order_id, amount: amount })
      ) { act(SetPaymentAmount.new(order_id: order_id, amount: amount)) }
      assert_requested(stub_update)
    end

    private

    def stub_creating_payment_intent(json)
      stub_request(:post, "https://api.stripe.com/v1/payment_intents").
        to_return(status: 200, :body => json)
    end

    def stub_updating_payment_intent(id, json)
      stub_request(:post, "https://api.stripe.com/v1/payment_intents/#{id}").
        to_return(status: 200, :body => json)
    end

    def payment_intent_json(intent_id, amount)
      {
        "id": intent_id,
        "object": "payment_intent",
        "amount": amount,
        "amount_capturable": 0,
        "amount_details": {
          "tip": {}
        },
        "amount_received": 0,
        "application": nil,
        "application_fee_amount": nil,
        "automatic_payment_methods": nil,
        "canceled_at": nil,
        "cancellation_reason": nil,
        "capture_method": "manual",
        "charges": {
          "object": "list",
          "data": [],
          "has_more": false,
          "url": "/v1/charges?payment_intent=#{intent_id}"
        },
        "client_secret": "#{intent_id}_secret_mMwz7FuwEvCg4nBxPseGCYjSk",
        "confirmation_method": "automatic",
        "created": 1667837463,
        "currency": "usd",
        "customer": nil,
        "description": "Order 12448b0b-a0b6-4bb7-9953-21705cf297ed",
        "invoice": nil,
        "last_payment_error": nil,
        "livemode": false,
        "metadata": {
          "payment_id": "Payments::Payment$12448b0b-a0b6-4bb7-9953-21705cf297ed"
        },
        "next_action": nil,
        "on_behalf_of": nil,
        "payment_method": nil,
        "payment_method_options": {
          "card": {
            "installments": nil,
            "mandate_options": nil,
            "network": nil,
            "request_three_d_secure": "automatic"
          }
        },
        "payment_method_types": [
          "card"
        ],
        "processing": nil,
        "receipt_email": nil,
        "review": nil,
        "setup_future_usage": nil,
        "shipping": nil,
        "statement_descriptor": nil,
        "statement_descriptor_suffix": nil,
        "status": "requires_payment_method",
        "transfer_data": nil,
        "transfer_group": nil
      }.to_json
    end
  end
end
