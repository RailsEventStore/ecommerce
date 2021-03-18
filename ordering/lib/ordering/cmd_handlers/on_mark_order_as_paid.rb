module Ordering
  class OnMarkOrderAsPaid
    include CommandHandler

    def call(command)
      with_aggregate(Order, command.aggregate_id) do |order|
        order.confirm(command.transaction_id)
      end
    end
  end
end
