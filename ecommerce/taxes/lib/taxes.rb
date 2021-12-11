require 'infra'
require_relative 'taxes/commands'
require_relative 'taxes/events'
require_relative 'taxes/services'
require_relative 'taxes/product'

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
    end
  end
end
