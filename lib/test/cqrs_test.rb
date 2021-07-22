require_relative '../cqrs'
require_relative '../../test/test_helper'


class CqrsTest < Ecommerce::InMemoryTestCase
  cover 'Cqrs*'

  class SomeCommand < Command; end

  class SomeCommandHandler
    def call(cmd)
    end
  end

  class SomeEvent < RailsEventStore::Event
  end

  def test_works
    cqrs = Cqrs.new(Rails.configuration.event_store, Rails.configuration.command_bus)
    cqrs.register_command(SomeCommandHandler.new, SomeCommand, [SomeEvent])

    assert_equal(
      {SomeCommand => [SomeEvent]},
      cqrs.to_hash
    )
  end
end