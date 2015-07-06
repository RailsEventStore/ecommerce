module CommandHandlers
  class RemoveItemFromBasket
    include Commands::Handler

    def call(command)
      with_aggregate(command.aggregate_id) do |order|
        order.remove_item(command.product_id)
      end
    end

    def aggregate_class
      Domain::Order
    end
  end
end
