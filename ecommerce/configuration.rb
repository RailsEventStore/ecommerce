require_relative "ordering/lib/ordering"
require_relative "pricing/lib/pricing"
require_relative "product_catalog/lib/product_catalog"
require_relative "crm/lib/crm"
require_relative "payments/lib/payments"
require_relative "inventory/lib/inventory"
require_relative "shipping/lib/shipping"
require_relative "invoicing/lib/invoicing"
require_relative "taxes/lib/taxes"
require_relative "processes/lib/processes"

module Ecommerce
  class Configuration
    def initialize(number_generator: nil, payment_gateway: nil, available_vat_rates: [])
      @number_generator = number_generator
      @payment_gateway = payment_gateway
      @available_vat_rates = available_vat_rates
    end

    def call(cqrs)
      configure_bounded_contexts(cqrs)
      configure_processes(cqrs)
    end

    def configure_bounded_contexts(cqrs)
      raise ArgumentError.new(
        "Neither number_generator nor payment_gateway can be null"
      ) if @number_generator.nil? || @payment_gateway.nil?
      [
        Shipments::Configuration.new,
        Ordering::Configuration.new(@number_generator),
        Pricing::Configuration.new,
        Payments::Configuration.new(@payment_gateway),
        ProductCatalog::Configuration.new,
        Crm::Configuration.new,
        Inventory::Configuration.new,
        Shipping::Configuration.new,
        Invoicing::Configuration.new,
        Taxes::Configuration.new(@available_vat_rates)
      ].each { |c| c.call(cqrs) }
    end

    def configure_processes(cqrs)
      Processes::Configuration.new.call(cqrs)
    end
  end
end
