require_relative "test_helper"

module Infra
  class ProcessTest < Minitest::Test
    cover "Infra::Process"

    Event = Struct.new(:data)
    Command = Struct.new(:order_id, :amount)

    def test_builds_command_from_event_data
      event_store = Object.new
      command_bus = Object.new
      event_store.define_singleton_method(:subscribe) { |subscriber, to:| subscriber.call(Event.new({ order_id: "order-1", discount: 10 })) }
      command_bus.define_singleton_method(:call) { |command| @command = command }

      Process.new(event_store, command_bus).call(
        Event,
        [:order_id, :discount],
        Command
      )

      assert_equal "order-1", command_bus.instance_variable_get(:@command).order_id
      assert_equal 10, command_bus.instance_variable_get(:@command).amount
    end
  end
end
