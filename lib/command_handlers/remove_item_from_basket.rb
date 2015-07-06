module CommandHandlers
  class RemoveItemFromBasket < Command::Handler
    def call(command)
      with_aggregate(command.aggregate_id) do |order|
        order.remove_item(command.product_id)
      end
    end

    private
    def aggregate_class
      Domain::Order
    end
  end
end
