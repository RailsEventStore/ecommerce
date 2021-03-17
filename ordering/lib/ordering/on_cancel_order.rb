module Ordering
  class OnCancelOrder
    include CommandHandler

    def call(command)
      with_aggregate(Order, command.aggregate_id) do |order|
        order.cancel
      end
    end
  end
end