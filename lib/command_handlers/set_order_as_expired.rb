module CommandHandlers
  class SetOrderAsExpired
    include Command::Handler

    def call(command)
      with_aggregate(Domain::Order, command.aggregate_id) do |order|
        order.expire
      end
    end
  end
end
