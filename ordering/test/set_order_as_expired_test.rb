require 'test_helper'

module Ordering
  class SetOrderAsExpiredTest < ActiveSupport::TestCase
    include TestCase

    cover 'Ordering::OnSetOrderAsExpired*'

    test 'draft order will expire' do
      aggregate_id = SecureRandom.uuid
      stream = "Ordering::Order$#{aggregate_id}"
      product = Product.create(name: 'test')
      arrange(stream, [ItemAddedToBasket.new(data: {order_id: aggregate_id, product_id: product.id})])

      published = act(stream, SetOrderAsExpired.new(order_id: aggregate_id))

      assert_changes(published, [OrderExpired.new(data: {order_id: aggregate_id})])
    end
  end
end