module CommandHandlers
  class AddItemToBasket
    include Command::Handler

    def call(command)
      with_aggregate(Domain::Order, command.aggregate_id) do |order|
        order.add_item(command.product_id)
      end
    end
  end
end
