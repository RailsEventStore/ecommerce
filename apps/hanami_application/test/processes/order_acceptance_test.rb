require "test_helper"

class OrderAcceptanceTest < Minitest::Test
  def test_issues_accept_offer_for_a_nonempty_order
    commands = []
    order_id = SecureRandom.uuid
    event_store = Infra::EventStore.in_memory
    process = HanamiApplication::Processes::OrderAcceptance.new(
      commands.method(:push), Orders.new({ order_id => 2 })
    )
    process.subscribe(event_store)

    event_store.publish(Pricing::OrderAcceptanceRequested.new(data: { order_id: order_id }))

    assert_equal(1, commands.size)
    assert_instance_of(Pricing::AcceptOffer, commands.first)
    assert_equal(order_id, commands.first.order_id)
  end

  def test_does_not_issue_commands_for_an_empty_order
    commands = []
    order_id = SecureRandom.uuid
    event_store = Infra::EventStore.in_memory
    process = HanamiApplication::Processes::OrderAcceptance.new(
      commands.method(:push), Orders.new({ order_id => 0 })
    )
    process.subscribe(event_store)

    assert_raises(HanamiApplication::Processes::OrderAcceptance::IsEmpty) do
      event_store.publish(Pricing::OrderAcceptanceRequested.new(data: { order_id: order_id }))
    end

    assert_empty(commands)
  end

  Orders = Data.define(:counts) do
    def item_count(order_id)
      counts.fetch(order_id)
    end
  end
end
