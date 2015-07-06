require 'test_helper'

module CommandHandlers
  class SetOrderAsExpiredTest < ActiveSupport::TestCase
    test 'draft order will expire' do
      with_aggregate do |id, event_store|
        product_id = 102
        arrange(event_store, Events::ItemAddedToBasket.create(id, product_id))

        act(event_store, Commands::SetOrderAsExpired.new(order_id: id))

        assert_changes(event_store, Events::OrderExpired.create(id))
      end
    end

    test 'created order could not be expired' do
      with_aggregate do |id, event_store|
        customer_id = 1
        order_number = "123/08/2015"
        arrange(event_store, Events::OrderCreated.create(id, order_number, customer_id))

        assert_raises(Domain::Order::AlreadyCreated) do
          act(event_store, Commands::SetOrderAsExpired.new(order_id: id))
        end
        assert_no_changes(event_store)
      end
    end
  end
end
