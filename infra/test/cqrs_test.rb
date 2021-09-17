require_relative "test_helper"

module Infra
  class CqrsTest < Minitest::Test
    cover "Infra::Cqrs*"

    class SomeCommand < Infra::Command
    end

    class SomeCommandHandler
      def call(cmd); end
    end

    class SomeEvent < RubyEventStore::Event
    end

    def test_works
      cqrs = Cqrs.new(event_store, command_bus)
      cqrs.register_command(SomeCommandHandler.new, SomeCommand, [SomeEvent])

      assert_equal({ SomeCommand => [SomeEvent] }, cqrs.to_hash)
    end

    def command_bus
      Arkency::CommandBus.new
    end

    def event_store
      RubyEventStore::Client.new(
        repository: RubyEventStore::InMemoryRepository.new
      )
    end
  end
end
