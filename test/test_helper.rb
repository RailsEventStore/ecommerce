ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'support/test_plumbing'
require 'simplecov'
require 'mutant/minitest/coverage'

class ActiveSupport::TestCase

  def setup
    Rails.configuration.event_store = event_store
    Rails.configuration.command_bus = command_bus

    Configuration.new.call(
      event_store,
      command_bus
    )
  end

  def run_command(command)
    command_bus.call(command)
  end

  def command_bus
    @command_bus ||= Arkency::CommandBus.new
  end

  def event_store
    @event_store ||= RailsEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new)
  end
end

SimpleCov.start
