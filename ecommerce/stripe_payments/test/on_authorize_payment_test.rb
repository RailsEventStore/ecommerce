require_relative "test_helper"

module Payments
  class OnAuthorizePaymentTest < Test
    cover "Payments::OnCapturePayment*"

    def test_authorize_payment
      order_id = SecureRandom.uuid
      amount = 20
      intent_id = "pi_1F5QxUC9bKSp3hWJgGrHksGL"
      payment_method_id = "pm_1EUt3RJX9HHJ5bycb1MyDZqY"
      stream = "Payments::Payment$#{order_id}"
      stub_creating_payment_intent(payment_intent_json(intent_id, amount, 'requires_payment_method'))
      stub_creating_payment_method(payment_method_json(payment_method_id))
      stub_authorize = stub_confirming_payment_intent(intent_id, payment_intent_json(intent_id, amount, 'requires_capture'))
      Client.new.create_test_payment_method

      arrange(
        SetPaymentAmount.new(order_id: order_id, amount: 20),
      )

      assert_events(
        stream,
        PaymentAuthorized.new(data: { order_id: order_id })
      ) { act(AuthorizePayment.new(order_id: order_id, payment_method_id: payment_method_id)) }
      assert_requested(stub_authorize)
    end

    def test_two_step_authorize_payment
      order_id = SecureRandom.uuid
      amount = 20
      intent_id = "pi_1F5QxUC9bKSp3hWJgGrHksGL"
      payment_method_id = "pm_1EUt3RJX9HHJ5bycb1MyDZqY"
      stream = "Payments::Payment$#{order_id}"
      stub_creating_payment_intent(payment_intent_json(intent_id, amount, 'requires_payment_method'))
      stub_creating_payment_method(payment_method_json(payment_method_id))
      stub_authorize = stub_confirming_payment_intent(intent_id, payment_intent_json(intent_id, amount, 'requires_action'))
      Client.new.create_test_payment_method

      arrange(
        SetPaymentAmount.new(order_id: order_id, amount: 20),
      )

      assert_events(
        stream,
        PaymentIntentActionRequired.new(
          data: {
            order_id: order_id,
            intent_id: intent_id,
            payment_method_id: payment_method_id,
            client_secret: "#{intent_id}_secret_mMwz7FuwEvCg4nBxPseGCYjSk"
          }
        )
      ) { act(AuthorizePayment.new(order_id: order_id, payment_method_id: payment_method_id)) }
      assert_requested(stub_authorize)

      stub_authorize = stub_confirming_payment_intent(intent_id, payment_intent_json(intent_id, amount, 'requires_capture'))

      assert_events(
        stream,
        PaymentAuthorized.new(data: { order_id: order_id })
      ) { act(AuthorizePayment.new(order_id: order_id, payment_method_id: nil)) }
      assert_requested(stub_authorize, times: 2)
    end

    private

    def stub_capturing_payment_intent(id, json)
      stub_request(:post, "https://api.stripe.com/v1/payment_intents/#{id}/capture").
        to_return(status: 200, :body => json)
    end

    def stub_creating_payment_method(json)
      stub_request(:post, "https://api.stripe.com/v1/payment_methods").
        to_return(status: 200, :body => json)
    end

    def stub_creating_payment_intent(json)
      stub_request(:post, "https://api.stripe.com/v1/payment_intents").
        to_return(status: 200, :body => json)
    end

    def stub_confirming_payment_intent(id, json)
      stub_request(:post, "https://api.stripe.com/v1/payment_intents/#{id}/confirm").
        to_return(status: 200, :body => json)
    end

    def payment_intent_json(intent_id, amount, status)
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
        "status": status,
        "transfer_data": nil,
        "transfer_group": nil
      }.to_json
    end

    def payment_method_json(payment_method_id)
      {
        "id": payment_method_id,
        "object": "payment_method",
        "billing_details": {
          "address": {
            "city": nil,
            "country": nil,
            "line1": nil,
            "line2": nil,
            "postal_code": nil,
            "state": nil
          },
          "email": nil,
          "name": nil,
          "phone": nil
        },
        "card": {
          "brand": "visa",
          "checks": {
            "address_line1_check": nil,
            "address_postal_code_check": nil,
            "cvc_check": nil
          },
          "country": "US",
          "exp_month": 8,
          "exp_year": 2020,
          "fingerprint": "rUAVhBoTJ09Ktza6",
          "funding": "credit",
          "generated_from": nil,
          "last4": "4242",
          "networks": {
            "available": [
              "visa"
            ],
            "preferred": nil
          },
          "three_d_secure_usage": {
            "supported": true
          },
          "wallet": nil
        },
        "created": 1556619557,
        "customer": nil,
        "livemode": false,
        "metadata": {},
        "type": "card"
      }.to_json
    end
  end
end
