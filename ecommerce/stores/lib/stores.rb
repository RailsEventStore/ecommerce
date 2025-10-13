require "infra"
require_relative "stores/commands"
require_relative "stores/events"
require_relative "stores/registration"

module Stores

  class Configuration
    def call(event_store, command_bus)
      command_bus.register(RegisterStore, Registration.new(event_store))
    end
  end
end
