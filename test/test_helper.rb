ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'support/test_plumbing'
require 'mutant/minitest/coverage'

module Ecommerce
  class InMemoryTestCase < ActiveSupport::TestCase
    setup do
      Rails.configuration.event_store = RailsEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new)
      Rails.configuration.command_bus = Arkency::CommandBus.new

      Configuration.new.call(
        Rails.configuration.event_store,
        Rails.configuration.command_bus
      )
    end

    def run_command(command)
      Rails.configuration.command_bus.call(command)
    end
  end

  class InMemoryIntegrationTestCase < ActionDispatch::IntegrationTest
    setup do
      Rails.configuration.event_store = RailsEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new)
      Rails.configuration.command_bus = Arkency::CommandBus.new

      Configuration.new.call(
        Rails.configuration.event_store,
        Rails.configuration.command_bus
      )
    end

    def run_command(command)
      Rails.configuration.command_bus.call(command)
    end
  end
end
