require 'test_helper'

module CommandHandlers
  class AddItemToBasketTest < ActiveSupport::TestCase
    include CommandHandlers::TestCase

    test 'item is added to draft order' do
      event_store = FakeEventStore.new
      aggregate_id = SecureRandom.uuid
      product_id = 102
      act(event_store, Command::AddItemToBasket.new(order_id: aggregate_id, product_id: product_id))
      assert_changes(event_store, [Events::ItemAddedToBasket.new(order_id: aggregate_id, product_id: product_id)])
    end

    test 'no add allowed to created order' do
      event_store = FakeEventStore.new
      aggregate_id = SecureRandom.uuid
      customer_id = 1
      order_number = "123/08/2015"
      product_id = 102
      arrange(event_store, [Events::OrderCreated.new(order_id: aggregate_id, order_number: order_number, customer_id: customer_id)])

      assert_raises(Domain::Order::AlreadyCreated) do
        act(event_store, Command::AddItemToBasket.new(order_id: aggregate_id, product_id: product_id))
      end
      assert_no_changes(event_store)
    end
  end
end
