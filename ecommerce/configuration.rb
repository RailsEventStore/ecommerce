require_relative "authentication/lib/authentication"
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

    def call(event_store, command_bus)
      configure_bounded_contexts
      configure_processes(event_store, command_bus)
    end

    def configure_bounded_contexts
      event_store = Rails.configuration.event_store
      command_bus = Rails.configuration.command_bus

      raise ArgumentError.new(
        "Neither number_generator nor payment_gateway can be null"
      ) if @number_generator.nil? || @payment_gateway.nil?
      [
        Authentication::Configuration.new,
        Ordering::Configuration.new(@number_generator),
        Crm::Configuration.new,
        Inventory::Configuration.new,
        Invoicing::Configuration.new,
        Payments::Configuration.new(@payment_gateway),
        Shipping::Configuration.new,
        Pricing::Configuration.new,
        Taxes::Configuration.new(@available_vat_rates),
        ProductCatalog::Configuration.new,
      ].each { |c| c.call(event_store, command_bus) }
    end

    def configure_processes(event_store, command_bus)
      Processes::Configuration.new.call(event_store, command_bus)
    end
  end
end
