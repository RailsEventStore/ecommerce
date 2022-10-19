require "rails_event_store"
require "arkency/command_bus"

require_relative "../../lib/configuration"

Rails.configuration.to_prepare do

  Rails.configuration.event_store = Infra::EventStore.main
  Rails.configuration.command_bus = Arkency::CommandBus.new

  cqrs = Infra::Cqrs.new(Rails.configuration.event_store, Rails.configuration.command_bus)

  Rails.configuration.cqrs = cqrs
  Configuration.new.call(cqrs)
end