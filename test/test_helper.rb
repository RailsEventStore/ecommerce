ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'support/test_case'
require 'simplecov'
require 'mutant/minitest/coverage'


class ActiveSupport::TestCase
  fixtures :all

  setup do
    repository =
      RailsEventStoreActiveRecord::EventRepository.new(serializer: RubyEventStore::NULL)
    Rails.configuration.event_store =
      RailsEventStore::Client.new(repository: repository)
    Rails.configuration.command_bus =
      Arkency::CommandBus.new
    Configuration.new.call(
      Rails.configuration.event_store,
      Rails.configuration.command_bus
    )
  end
end

SimpleCov.start
