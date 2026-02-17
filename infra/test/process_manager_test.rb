require_relative "test_helper"

module Infra
  class SimpleProcessManagerTest < Minitest::Test
    cover "Infra::ProcessManager*"

    class OrderPaid       < RubyEventStore::Event; end
    class OrderAddressSet < RubyEventStore::Event; end

    class ShipOrder
      def initialize(order_id)
        @order_id = order_id
      end
    end

    class SimpleProcessManager < Infra::ProcessManager
      subscribes_to OrderPaid, OrderAddressSet

      private

      def initial_state
        ProcessState.new
      end

      def act
        puts state.inspect
        case state
        in { paid: true, address: true }
          command_bus.call(ShipOrder.new(id))
        else

        end
      end

      def apply(event)
        case event
        when OrderPaid
          state.with(paid: true)
        when OrderAddressSet
          state.with(address: true)
        end
      end

      def fetch_id(event)
        event.data.fetch(:order_id)
      end

      ProcessState = Data.define(:paid, :address) do
        def initialize(paid: false, address: false) = super
      end
    end

    def test_published_command
      process = SimpleProcessManager.new(fake_event_store, fake_command_bus)
      order_paid = OrderPaid.new(data: {order_id: 1})
      address_set = OrderAddressSet.new(data: {order_id: 1, address: "foo"})
      fake_event_store.subscribe(process, to: SimpleProcessManager.subscribed_events)
      fake_event_store.publish(order_paid)
      assert_equal(0, fake_command_bus.all_received.count)
      fake_event_store.publish(address_set)
      assert_equal(1, fake_command_bus.all_received.count)
      assert_equal([order_paid, address_set], fake_event_store.read.stream("Infra::SimpleProcessManagerTest::SimpleProcessManager$1").to_a)
    end

    def test_subscribed_events
      assert_equal([OrderPaid, OrderAddressSet], SimpleProcessManager.subscribed_events)
    end

    def test_links_events_to_process_stream
      process = SimpleProcessManager.new(fake_event_store, fake_command_bus)
      order_paid = OrderPaid.new(data: {order_id: 1})
      fake_event_store.publish(order_paid)
      process.call(order_paid)
      linked = fake_event_store.read.stream("Infra::SimpleProcessManagerTest::SimpleProcessManager$1").to_a
      assert_equal([order_paid], linked)
    end

    def test_builds_state_from_past_events
      process = SimpleProcessManager.new(fake_event_store, fake_command_bus)
      order_paid = OrderPaid.new(data: {order_id: 2})
      address_set = OrderAddressSet.new(data: {order_id: 2, address: "foo"})
      fake_event_store.subscribe(process, to: SimpleProcessManager.subscribed_events)
      fake_event_store.publish(order_paid)
      assert_equal(0, fake_command_bus.all_received.count)
      fake_event_store.publish(address_set)
      assert_equal(1, fake_command_bus.all_received.count)
    end

    def test_retries_on_concurrency_error
      store = FailOnFirstLinkEventStore.new
      process = SimpleProcessManager.new(store, fake_command_bus)
      order_paid = OrderPaid.new(data: {order_id: 3})
      store.publish(order_paid)
      process.call(order_paid)
      linked = store.read.stream("Infra::SimpleProcessManagerTest::SimpleProcessManager$3").to_a
      assert_equal([order_paid], linked)
    end

    def test_links_with_expected_version
      store = ExpectedVersionVerifyingEventStore.new
      process = SimpleProcessManager.new(store, fake_command_bus)
      order_paid = OrderPaid.new(data: {order_id: 4})
      store.publish(order_paid)
      process.call(order_paid)
      assert_equal(-1, store.last_expected_version)
    end

    private

    def fake_event_store
      @fake_event_store ||= RubyEventStore::Client.new
    end

    def fake_command_bus
      @fake_command_bus ||= FakeCommandBus.new
    end
  end

  class ExpectedVersionVerifyingEventStore < SimpleDelegator
    attr_reader :last_expected_version

    def initialize
      super(RubyEventStore::Client.new)
    end

    def link(event_ids, expected_version:, **kwargs)
      @last_expected_version = expected_version
      __getobj__.link(event_ids, expected_version:, **kwargs)
    end
  end

  class FailOnFirstLinkEventStore < SimpleDelegator
    def initialize
      super(RubyEventStore::Client.new)
      @link_attempts = 0
    end

    def link(event_ids, **kwargs)
      @link_attempts += 1
      raise RubyEventStore::WrongExpectedEventVersion if @link_attempts == 1
      __getobj__.link(event_ids, **kwargs)
    end
  end

  class FakeCommandBus
    attr_reader :all_received

    def initialize
      @all_received = []
    end

    def call(command)
      @all_received << command
    end

    def clear
      @all_received = []
    end
  end
end
