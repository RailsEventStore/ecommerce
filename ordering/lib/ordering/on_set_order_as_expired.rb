module Ordering
  class OnSetOrderAsExpired
    include CommandHandler

    def call(command)
      with_aggregate(Order, command.aggregate_id) do |order|
        order.expire
      end
    end
  end
end