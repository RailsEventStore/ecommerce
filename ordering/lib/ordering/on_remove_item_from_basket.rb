module Ordering
  class OnRemoveItemFromBasket
    include CommandHandler

    def call(command)
      with_aggregate(Order, command.aggregate_id) do |order|
        order.remove_item(command.product_id)
      end
    end
  end
end
