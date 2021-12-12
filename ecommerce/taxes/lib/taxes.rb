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

    def call(cqrs)
      @@available_vat_rates = @available_vat_rates
      cqrs.register_command(SetVatRate, SetVatRateHandler.new(cqrs.event_store), VatRateSet)
      cqrs.register_command(DetermineVatRate, DetermineVatRateHandler.new(cqrs.event_store), VatRateDetermined)
    end
  end
end
