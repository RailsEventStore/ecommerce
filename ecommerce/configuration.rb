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
      cqrs = Infra::Cqrs.new(event_store, command_bus)
      configure_bounded_contexts(cqrs)
      configure_processes(cqrs)
    end

    def configure_bounded_contexts(cqrs)
      event_store = Rails.configuration.event_store
      command_bus = Rails.configuration.command_bus

      raise ArgumentError.new(
        "Neither number_generator nor payment_gateway can be null"
      ) if @number_generator.nil? || @payment_gateway.nil?
      [
        Shipments::Configuration.new,
        Pricing::Configuration.new,
        Payments::Configuration.new(@payment_gateway),
        ProductCatalog::Configuration.new,
        Inventory::Configuration.new,
        Shipping::Configuration.new,
        Invoicing::Configuration.new,
        Taxes::Configuration.new(@available_vat_rates)
      ].each { |c| c.call(cqrs) }

      [
        Authentication::Configuration.new,
        Ordering::Configuration.new(@number_generator),
        Crm::Configuration.new,
      ].each { |c| c.call(event_store, command_bus) }
    end

    def configure_processes(cqrs)
      Processes::Configuration.new.call(cqrs)
    end
  end
end
