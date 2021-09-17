require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../lib/payments"
require_relative "../../product_catalog/lib/product_catalog"
require_relative "../../pricing/lib/pricing"
require_relative "../../ordering/lib/ordering"
require_relative "../../crm/lib/crm"

module Payments
  class Test < Infra::InMemoryTest
    attr_reader :payment_gateway

    def before_setup
      super
      @payment_gateway = FakeGateway.new
      Configuration.new(cqrs, event_store, -> { @payment_gateway }).call
      ProductCatalog::Configuration.new(cqrs).call
      Pricing::Configuration.new(cqrs, event_store).call
      Ordering::Configuration.new(
        cqrs,
        event_store,
        -> { Ordering::FakeNumberGenerator.new }
      ).call
      Crm::Configuration.new(cqrs, Crm::InMemoryCustomerRepository.new).call

      cqrs.subscribe(
        ->(event) do
          cqrs.run(
            Payments::SetPaymentAmount.new(
              order_id: event.data.fetch(:order_id),
              amount: event.data.fetch(:discounted_amount).to_f
            )
          )
        end,
        [Pricing::OrderTotalValueCalculated]
      )
    end
  end
end
