module CommandHandlers
  class SetOrderAsExpired < Command::Handler
    def call(command)
      with_aggregate(command.aggregate_id) do |order|
        order.expire
      end
    end

    private
    def aggregate_class
      Domain::Order
    end
  end
end
