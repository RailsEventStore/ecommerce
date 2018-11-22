require 'test_helper'

module CommandHandlers
  class SetOrderAsExpiredTest < ActiveSupport::TestCase
    include TestCase

    test 'draft order will expire' do
      aggregate_id = SecureRandom.uuid
      stream = "Domain::Order$#{aggregate_id}"
      product = Product.create(name: 'test')
      arrange(stream, [Events::ItemAddedToBasket.new(data: {order_id: aggregate_id, product_id: product.id})])

      published = act(stream, Command::SetOrderAsExpired.new(order_id: aggregate_id))

      assert_changes(published, [Events::OrderExpired.new(data: {order_id: aggregate_id})])
    end

  end
end
