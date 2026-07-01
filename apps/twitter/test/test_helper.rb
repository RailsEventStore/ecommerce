ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mutant/minitest/coverage"

ActiveJob::Base.logger = Logger.new(nil)

class InMemoryRESTestCase < ActiveSupport::TestCase
  def before_setup
    result = super
    @previous_event_store = Rails.configuration.event_store
    @previous_command_bus = Rails.configuration.command_bus
    Rails.configuration.event_store = Infra::EventStore.in_memory
    Rails.configuration.command_bus = Arkency::CommandBus.new

    Configuration.new.call(
      Rails.configuration.event_store, Rails.configuration.command_bus
    )
    result
  end

  def before_teardown
    result = super
    Rails.configuration.event_store = @previous_event_store
    Rails.configuration.command_bus = @previous_command_bus
    result
  end

  def event_store
    Rails.configuration.event_store
  end

  def command_bus
    Rails.configuration.command_bus
  end
end

class InMemoryRESIntegrationTestCase < ActionDispatch::IntegrationTest
  def before_setup
    result = super
    @previous_event_store = Rails.configuration.event_store
    @previous_command_bus = Rails.configuration.command_bus
    Rails.configuration.event_store = Infra::EventStore.in_memory_rails
    Rails.configuration.command_bus = Arkency::CommandBus.new

    Configuration.new.call(Rails.configuration.event_store, Rails.configuration.command_bus)
    result
  end

  def before_teardown
    result = super
    Rails.configuration.event_store = @previous_event_store
    Rails.configuration.command_bus = @previous_command_bus
    result
  end

  def command_bus
    Rails.configuration.command_bus
  end
end
