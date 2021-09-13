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
    def initialize(cqrs)
      @cqrs = cqrs
    end

    def call
      @cqrs.register(AuthorizePayment, OnAuthorizePayment.new)
      @cqrs.register(CapturePayment, OnCapturePayment.new)
      @cqrs.register(ReleasePayment, OnReleasePayment.new)
      @cqrs.register(SetPaymentAmount, OnSetPaymentAmount.new)
    end
  end
end