module CommandHandlers
  class AddItemToBasket < Command::Handler
    def call(command)
      with_aggregate(command.aggregate_id) do |order|
        order.add_item(command.product_id)
      end
    end

    private
    def aggregate_class
      Domain::Order
    end
  end
end
