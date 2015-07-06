module CommandHandlers
  class CreateOrder < Command::Handler
    def initialize(repository:, number_generator:)
      super
      @number_generator = number_generator
    end

    def call(command)
      with_aggregate(command.aggregate_id) do |order|
        order_number = number_generator.call
        order.create(order_number, command.customer_id)
      end
    end

    private
    attr_accessor :number_generator

    def aggregate_class
      Domain::Order
    end
  end
end
