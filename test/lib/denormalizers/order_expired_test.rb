require 'test_helper'

module Denormalizers
  class OrderExpiredTest < ActiveSupport::TestCase
    include EventStoreSetup

    test 'expire created order' do
      customer = Customer.create(name: 'dummy')
      aggregate_id = SecureRandom.uuid
      order_number = "123/08/2015"
      event_store.publish_event(Events::OrderCreated.new(order_id: aggregate_id, order_number: order_number, customer_id: customer.id))

      event_store.publish_event(Events::OrderExpired.new(order_id: aggregate_id))

      assert_equal(::Order.count, 1)
      order = Order.find_by(uid: aggregate_id)
      assert_equal(order.state, 'Expired')
    end
  end
end
