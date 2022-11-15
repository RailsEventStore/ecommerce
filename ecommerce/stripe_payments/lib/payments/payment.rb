module Payments
  class Payment
    include AggregateRoot

    AlreadyAuthorized = Class.new(StandardError)
    NotAuthorized = Class.new(StandardError)
    AlreadyCaptured = Class.new(StandardError)
    AlreadyReleased = Class.new(StandardError)
    IntentNotRegistered = Class.new(StandardError)

    def set_amount(order_id, amount)
      if intent_registered?
        gateway.update_intent_amount(@intent_id, amount)
      else
        intent = gateway.register_intent(order_id, amount)
        apply(PaymentIntentRegistered.new(data: { order_id: order_id, intent_id: intent.id }))
      end
      apply(PaymentAmountSet.new(data: { order_id: order_id, amount: amount }))
    end

    def authorize(payment_method_id = nil)
      raise IntentNotRegistered unless intent_registered?
      raise AlreadyAuthorized if authorized?

      intent = if payment_method_id
                 gateway.confirm_intent(@intent_id, payment_method_id)
               elsif payment_method_chosen?
                 payment_method_id = @payment_method_id
                 gateway.confirm_intent(@intent_id)
               else
                 raise ArgumentError.new "Payment method required"
               end
      case intent.status
      when 'requires_action'
        apply(PaymentIntentActionRequired.new(data: { order_id: @order_id, intent_id: @intent_id, payment_method_id: payment_method_id, client_secret: intent.client_secret }))
      when 'requires_payment_method'
        apply(PaymentIntentFailed.new(data: { order_id: @order_id, intent_id: @intent_id, payment_method_id: payment_method_id }))
      when 'requires_capture'
        apply(PaymentAuthorized.new(data: { order_id: @order_id }))
      end
    end

    def capture
      raise AlreadyCaptured if captured?
      raise NotAuthorized unless authorized?
      gateway.capture_intent(@intent_id, @amount)
      apply(PaymentCaptured.new(data: { order_id: @order_id }))
    end

    def release
      raise AlreadyReleased if released?
      raise AlreadyCaptured if captured?
      raise NotAuthorized unless authorized?
      gateway.cancel_intent(@intent_id)
      apply(PaymentReleased.new(data: { order_id: @order_id }))
    end

    private

    def gateway
      Client.new
    end

    on PaymentAmountSet do |event|
      @amount = event.data.fetch(:amount)
      @order_id = event.data.fetch(:order_id)
    end

    on PaymentAuthorized do |event|
      @state = :authorized
    end

    on PaymentCaptured do |event|
      @state = :captured
    end

    on PaymentReleased do |event|
      @state = :released
    end

    on PaymentIntentRegistered do |event|
      @intent_id = event.data.fetch(:intent_id)
    end

    on PaymentIntentActionRequired do |event|
      @payment_method_id = event.data.fetch(:payment_method_id)
    end

    on PaymentIntentFailed do |event|
      @payment_method_id = nil
    end

    on PaymentIntentConfirmationRequired do |event|
      @payment_method_id = event.data.fetch(:payment_method_id)
    end

    def authorized?
      @state.equal?(:authorized)
    end

    def captured?
      @state.equal?(:captured)
    end

    def released?
      @state.equal?(:released)
    end

    def payment_method_chosen?
      @payment_method_id.present?
    end

    def intent_registered?
      @intent_id.present?
    end
  end
end
