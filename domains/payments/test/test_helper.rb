require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../lib/payments"

module Payments
  class Test < Infra::InMemoryTest
    attr_reader :payment_gateway

    def before_setup
      super
      @payment_gateway = FakeGateway.new
      Configuration.new(-> { @payment_gateway }).call(event_store, command_bus)
    end
  end
end
