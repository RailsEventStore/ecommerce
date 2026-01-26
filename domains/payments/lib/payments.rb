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

    def call(event_store, command_bus)
      command_bus.register(
        AuthorizePayment,
        OnAuthorizePayment.new(event_store, @gateway)
      )
      command_bus.register(CapturePayment, OnCapturePayment.new(event_store))
      command_bus.register(ReleasePayment, OnReleasePayment.new(event_store))
      command_bus.register(SetPaymentAmount, OnSetPaymentAmount.new(event_store))
    end
  end
end
