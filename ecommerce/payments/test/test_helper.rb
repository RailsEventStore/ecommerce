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
      ecommerce_configuration = Ecommerce::Configuration.new
      [
        Configuration.new(-> { @payment_gateway }),
        ProductCatalog::Configuration.new,
        Pricing::Configuration.new,
        Ordering::Configuration.new(-> { Ordering::FakeNumberGenerator.new }),
        Crm::Configuration.new,
        ecommerce_configuration.public_method(:notify_payments_about_order_total_value),
        ecommerce_configuration.public_method(:enable_pricing_sync_from_ordering),
        ecommerce_configuration.public_method(:calculate_total_value_when_order_submitted)
      ].each { |c| c.call(cqrs) }
    end
  end
end
