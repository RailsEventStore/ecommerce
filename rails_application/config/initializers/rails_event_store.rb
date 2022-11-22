require "rails_event_store"
require "arkency/command_bus"

require_relative "../../lib/configuration"

Rails.configuration.to_prepare do
  Sidekiq.strict_args!(false)
  Rails.configuration.event_store = Infra::EventStore.main
  Rails.configuration.command_bus = Arkency::CommandBus.new

  Configuration.new.call(Rails.configuration.event_store, Rails.configuration.command_bus)
end