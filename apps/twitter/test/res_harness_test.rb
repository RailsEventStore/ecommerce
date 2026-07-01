require "test_helper"

class RESHarnessTest < InMemoryRESTestCase
  def test_publishes_and_reads_events_from_in_memory_store
    event = RubyEventStore::Event.new(event_id: SecureRandom.uuid, data: { hello: "twitter" })

    event_store.publish(event, stream_name: "harness")

    assert_equal 1, event_store.read.stream("harness").count
  end

  def test_command_bus_is_available
    assert_instance_of Arkency::CommandBus, command_bus
  end
end
