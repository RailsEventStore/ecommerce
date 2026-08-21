require "infra"
require_relative "product_catalog/commands"
require_relative "product_catalog/events"
require_relative "product_catalog/registration"
require_relative "product_catalog/naming"
require_relative "product_catalog/name_change_requesting"
require_relative "product_catalog/moderation"
require_relative "product_catalog/fake_name_moderation"

module ProductCatalog

  class Configuration
    def initialize(name_moderation = nil)
      @name_moderation = name_moderation
    end

    def call(event_store, command_bus)
      command_bus.register(RegisterProduct, Registration.new(event_store))
      command_bus.register(NameProduct, Naming.new(event_store))
      command_bus.register(RequestProductNameChange, NameChangeRequesting.new(event_store))
      command_bus.register(ModerateProductName, Moderation.new(event_store, @name_moderation)) if @name_moderation
    end
  end
end
