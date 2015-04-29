module CommandHandlers
  class SetOrderAsExpired
    include CommandHandler

    def call(command)
      with_aggregate(command.aggregate_id) do |order|
        order.expire
      end
    end

    def aggregate_class
      Domain::Order
    end
  end
end
