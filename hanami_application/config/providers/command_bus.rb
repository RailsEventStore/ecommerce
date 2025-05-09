# frozen_string_literal: true

Hanami.application.register_provider :command_bus do
  start do
    # Command bus registration
    require "arkency/command_bus"
    register "command_bus", Arkency::CommandBus.new
  end
end
