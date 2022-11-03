require "infra"
require_relative "product_catalog/commands"
require_relative "product_catalog/events"
require_relative "product_catalog/registration"
require_relative "product_catalog/naming"

module ProductCatalog

  class Configuration
    def call(event_store, command_bus)
      command_bus.register(RegisterProduct, Registration.new(event_store))
      command_bus.register(NameProduct, Naming.new(event_store))
    end
  end
end
