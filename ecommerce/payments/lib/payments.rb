require_relative "../../../infra/lib/infra"
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
      cqrs = Infra::Cqrs.new(event_store, command_bus)

      cqrs.register(
        AuthorizePayment,
        OnAuthorizePayment.new(event_store, @gateway)
      )
      cqrs.register(CapturePayment, OnCapturePayment.new(event_store))
      cqrs.register(ReleasePayment, OnReleasePayment.new(event_store))
      cqrs.register(SetPaymentAmount, OnSetPaymentAmount.new(event_store))
    end
  end
end
