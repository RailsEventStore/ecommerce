require "infra"
require_relative "payments/commands"
require_relative "payments/events"
require_relative "payments/on_set_payment_amount"
require_relative "payments/on_authorize_payment"
require_relative "payments/on_capture_payment"
require_relative "payments/on_release_payment"
require_relative "payments/fake_gateway"
require_relative "payments/payment"

module Payments
  class Configuration
    def initialize(gateway)
      @gateway = gateway
    end

    def call(cqrs)
      cqrs.register_command(
        AuthorizePayment,
        OnAuthorizePayment.new(cqrs.event_store, @gateway)
      )
      cqrs.register_command(CapturePayment, OnCapturePayment.new(cqrs.event_store))
      cqrs.register_command(ReleasePayment, OnReleasePayment.new(cqrs.event_store))
      cqrs.register_command(SetPaymentAmount, OnSetPaymentAmount.new(cqrs.event_store))
    end
  end
end
