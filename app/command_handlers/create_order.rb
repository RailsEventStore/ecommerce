module CommandHandlers
  class CreateOrder
    include Injectors::ServicesInjector
    include CommandHandler

    def call(command)
      with_aggregate(command.aggregate_id) do |order|
        order_number = number_generator.call
        order.create(order_number, command.customer_id)
      end
    end

    def aggregate_class
      Domain::Order
    end
  end
end
