require 'test_helper'

module CommandHandlers
  class CreateOrderTest < ActiveSupport::TestCase
    test 'order is created' do
      with_aggregate do |id, event_store|
        customer_id = 1
        order_number = "123/08/2015"
        arrange(event_store, Events::ItemAddedToBasket.create(id, customer_id))

        act(event_store, Commands::CreateOrder.new(order_id: id, customer_id: customer_id))

        assert_changes(event_store, Events::OrderCreated.create(id, order_number, customer_id))
      end
    end

    test 'could not create order where customer is not given' do
      with_aggregate do |id, event_store|
        assert_raises(Command::ValidationError) do
          act(event_store, Commands::CreateOrder.new(order_id: id, customer_id: nil))
        end
        assert_no_changes(event_store)
      end
    end

    test 'already created order could not be created again' do
      with_aggregate do |id, event_store|
        customer_id = 1
        order_number = "123/08/2015"
        another_customer_id = 2
        arrange(event_store, Events::OrderCreated.create(id, order_number, customer_id))

        assert_raises(Domain::Order::AlreadyCreated) do
          act(event_store, Commands::CreateOrder.new(order_id: id, customer_id: another_customer_id))
        end
        assert_no_changes(event_store)
      end
    end

    test 'expired order could not be created' do
      with_aggregate do |id, event_store|
        customer_id = 1
        arrange(event_store, Events::OrderExpired.create(id))

        assert_raises(Domain::Order::OrderExpired) do
          act(event_store, Commands::CreateOrder.new(order_id: id, customer_id: customer_id))
        end
        assert_no_changes(event_store)
      end
    end
  end
end
