require "stripe"

module Payments
  class Client
    def initialize
      @client = Stripe::StripeClient.new(
        {
          api_key: ENV['STRIPE_KEY']
        }
      )
    end

    def register_intent(order_id, amount)
      call { Stripe::PaymentIntent.create(attributes_for_registration(order_id, amount)) }
    end

    def update_intent_amount(intent_id, amount)
      call { Stripe::PaymentIntent.update(intent_id, amount: amount_in_cents(amount)) }
    end

    def update_intent_payment_method(intent_id, payment_method_id)
      call { Stripe::PaymentIntent.update(intent_id, payment_method: payment_method_id, confirm: true) }
    end

    def confirm_intent(intent_id)
      call { Stripe::PaymentIntent.confirm(intent_id) }
    end

    def capture_intent(intent_id, amount)
      call { Stripe::PaymentIntent.capture(intent_id, amount: amount_in_cents(amount)) }
    end

    def cancel_intent(intent_id)
      call { Stripe::PaymentIntent.cancel(intent_id) }
    end

    def create_test_payment_method
      call do
        Stripe::PaymentMethod.create({
                                       type: 'card',
                                       card: {
                                         number: '4242424242424242',
                                         exp_month: 11,
                                         exp_year: 2023,
                                         cvc: '314',
                                       },
                                     })
      end
    end

    Error = Class.new(StandardError)

    private

    def call
      raise ArgumentError.new unless block_given?
      @client.request do
        yield
      end.first
    rescue Stripe::RateLimitError => e
      raise Error.new "Too many requests made to the API too quickly"
    rescue Stripe::InvalidRequestError => e
      raise Error.new "Invalid parameters were supplied to Stripe's API"
    rescue Stripe::AuthenticationError => e
      raise Error.new "Authentication with Stripe's API failed"
    rescue Stripe::APIConnectionError => e
      raise Error.new "Network communication with Stripe failed"
    rescue Stripe::StripeError => e
      raise Error.new e.message
    end

    def attributes_for_registration(order_id, amount)
      {
        amount: amount_in_cents(amount),
        currency: 'usd',
        description: "Order #{order_id}",
        capture_method: "manual",
        confirmation_method: "manual",
        metadata: {
          payment_id: order_id,
        }
      }
    end

    def amount_in_cents(amount)
      (amount * 100).to_i
    end
  end
end