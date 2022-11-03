require 'infra'
require_relative 'taxes/commands'
require_relative 'taxes/events'
require_relative 'taxes/services'
require_relative 'taxes/product'
require_relative 'taxes/vat_rate_catalog'

module Taxes
  class Configuration
    def self.available_vat_rates
      @@available_vat_rates
    end

    def initialize(available_vat_rates = [])
      @available_vat_rates = available_vat_rates
    end

    def call(event_store, command_bus)
      @@available_vat_rates = @available_vat_rates
      command_bus.register(SetVatRate, SetVatRateHandler.new(event_store))
      command_bus.register(DetermineVatRate, DetermineVatRateHandler.new(event_store))
    end
  end
end
