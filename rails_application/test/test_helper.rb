ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mutant/minitest/coverage"

module Ecommerce
  class InMemoryTestCase < ActiveSupport::TestCase
    def before_setup
      result = super
      @previous_event_store = Rails.configuration.event_store
      @previous_command_bus = Rails.configuration.command_bus
      Rails.configuration.event_store =
        RailsEventStore::Client.new(
          repository: RubyEventStore::InMemoryRepository.new
        )
      Rails.configuration.command_bus = Arkency::CommandBus.new

      Configuration.new.call(
        Infra::Cqrs.new(Rails.configuration.event_store, Rails.configuration.command_bus)
      )
      result
    end

    def before_teardown
      result = super
      Rails.configuration.event_store = @previous_event_store
      Rails.configuration.command_bus = @previous_command_bus
      result
    end

    def run_command(command)
      Rails.configuration.command_bus.call(command)
    end
  end

  class RealRESIntegrationTestCase < ActionDispatch::IntegrationTest
    def run_command(command)
      Rails.configuration.command_bus.call(command)
    end
  end

  class InMemoryRESIntegrationTestCase < ActionDispatch::IntegrationTest
    def before_setup
      result = super
      @previous_event_store = Rails.configuration.event_store
      @previous_command_bus = Rails.configuration.command_bus
      Rails.configuration.event_store =
        RailsEventStore::Client.new(
          repository: RubyEventStore::InMemoryRepository.new
        )
      Rails.configuration.command_bus = Arkency::CommandBus.new

      Configuration.new.call(
        Infra::Cqrs.new(Rails.configuration.event_store, Rails.configuration.command_bus)
      )
      result
    end

    def before_teardown
      result = super
      Rails.configuration.event_store = @previous_event_store
      Rails.configuration.command_bus = @previous_command_bus
      result
    end

    def run_command(command)
      Rails.configuration.command_bus.call(command)
    end
  end
end
