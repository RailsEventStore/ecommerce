module CommandHandlers
  class SubmitOrder
    include Command::Handler

    def initialize(number_generator:)
      @number_generator = number_generator
    end

    def call(command)
      with_aggregate(Domain::Order, command.aggregate_id) do |order|
        order_number = number_generator.call
        order.submit(order_number, command.customer_id)
      end
    end

    private
    attr_accessor :number_generator
  end
end
