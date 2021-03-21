module Ordering
  class OnAddItemToBasket
    include CommandHandler

    def call(command)
      with_aggregate(Order, command.aggregate_id) do |order|
        order.add_item(command.product_id)
      end

      with_aggregate(::Ecommerce::Cart, command.aggregate_id) do |cart|
        cart.add_item(command.product_id)
      end
    end
  end
end