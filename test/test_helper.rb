ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'support/test_plumbing'
require 'simplecov'
require 'mutant/minitest/coverage'

class ActiveSupport::TestCase
  fixtures :all

  setup do
    Rails.configuration.event_store =
      RailsEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new)
    Rails.configuration.command_bus =
      Arkency::CommandBus.new
    Configuration.new.call(
      Rails.configuration.event_store,
      Rails.configuration.command_bus
    )
  end
end

SimpleCov.start
