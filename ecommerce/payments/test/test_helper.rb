require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../lib/payments"
require_relative "../../product_catalog/lib/product_catalog"
require_relative "../../pricing/lib/pricing"
require_relative "../../ordering/lib/ordering"
require_relative "../../crm/lib/crm"
require_relative "../../configuration"

module Payments
  class Test < Infra::InMemoryTest
    attr_reader :payment_gateway

    def before_setup
      super
      @payment_gateway = FakeGateway.new
      Configuration.new(-> { @payment_gateway }).call(cqrs)
    end
  end
end
