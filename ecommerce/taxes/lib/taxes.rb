require 'infra'
require_relative 'taxes/commands'
require_relative 'taxes/events'
require_relative 'taxes/services'
require_relative 'taxes/product'
require_relative 'taxes/vat_rate_catalog'

module Taxes
  class Configuration
    def call(event_store, command_bus)
      command_bus.register(SetVatRate, SetVatRateHandler.new(event_store))
      command_bus.register(AddAvailableVatRate, AddAvailableVatRateHandler.new(event_store))
      command_bus.register(RemoveAvailableVatRate, RemoveAvailableVatRateHandler.new(event_store))
    end
  end
end
