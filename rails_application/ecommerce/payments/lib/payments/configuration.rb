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