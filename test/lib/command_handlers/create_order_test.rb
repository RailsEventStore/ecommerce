require 'test_helper'

module CommandHandlers
  class CreateOrderTest < ActiveSupport::TestCase
    include CommandHandlers::TestCase

    test 'order is created' do
      event_store = FakeEventStore.new
      aggregate_id = SecureRandom.uuid
      customer_id = 1
      order_number = "123/08/2015"
      arrange(event_store, Events::ItemAddedToBasket.create(aggregate_id, customer_id))

      act(event_store, Command::CreateOrder.new(order_id: aggregate_id, customer_id: customer_id))

      assert_changes(event_store, Events::OrderCreated.create(aggregate_id, order_number, customer_id))
    end

    test 'could not create order where customer is not given' do
      event_store = FakeEventStore.new
      aggregate_id = SecureRandom.uuid
      assert_raises(Command::ValidationError) do
        act(event_store, Command::CreateOrder.new(order_id: aggregate_id, customer_id: nil))
      end
      assert_no_changes(event_store)
    end

    test 'already created order could not be created again' do
      event_store = FakeEventStore.new
      aggregate_id = SecureRandom.uuid
      customer_id = 1
      order_number = "123/08/2015"
      another_customer_id = 2
      arrange(event_store, Events::OrderCreated.create(aggregate_id, order_number, customer_id))

      assert_raises(Domain::Order::AlreadyCreated) do
        act(event_store, Command::CreateOrder.new(order_id: aggregate_id, customer_id: another_customer_id))
      end
      assert_no_changes(event_store)
    end

    test 'expired order could not be created' do
      event_store = FakeEventStore.new
      aggregate_id = SecureRandom.uuid
      customer_id = 1
      arrange(event_store, Events::OrderExpired.create(aggregate_id))

      assert_raises(Domain::Order::OrderExpired) do
        act(event_store, Command::CreateOrder.new(order_id: aggregate_id, customer_id: customer_id))
      end
      assert_no_changes(event_store)
    end
  end
end
