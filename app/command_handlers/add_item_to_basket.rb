module CommandHandlers
  class AddItemToBasket
    include CommandHandler

    def call(command)
      with_aggregate(command.aggregate_id) do |order|
        order.add_item(command.product_id)
      end
    end

    def aggregate_class
      Domain::Order
    end
  end
end
