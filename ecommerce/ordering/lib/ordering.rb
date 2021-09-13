require_relative "../../../infra/lib/infra"
require_relative 'ordering/events/order_submitted'
require_relative 'ordering/events/order_expired'
require_relative 'ordering/events/order_paid'
require_relative 'ordering/events/order_cancelled'
require_relative 'ordering/commands/submit_order'
require_relative 'ordering/commands/set_order_as_expired'
require_relative 'ordering/commands/mark_order_as_paid'
require_relative 'ordering/commands/cancel_order'
require_relative 'ordering/fake_number_generator'
require_relative 'ordering/number_generator'
require_relative 'ordering/order'

module Ordering

  class OnCancelOrder
    include CommandHandler

    def call(command)
      with_aggregate(Order, command.aggregate_id) do |order|
        order.cancel
      end
    end
  end

  class OnMarkOrderAsPaid
    include CommandHandler

    def call(command)
      with_aggregate(Order, command.aggregate_id) do |order|
        order.confirm
      end
    end
  end

  class OnSetOrderAsExpired
    include CommandHandler

    def call(command)
      with_aggregate(Order, command.aggregate_id) do |order|
        order.expire
      end
    end
  end

  class OnSubmitOrder
    include CommandHandler

    def initialize(number_generator:)
      @number_generator = number_generator
    end

    def call(command)
      ActiveRecord::Base.transaction do
        with_aggregate(Order, command.aggregate_id) do |order|
          order_number = number_generator.call
          order.submit(order_number, command.customer_id)
        end
      end
    end

    private

    attr_accessor :number_generator
  end
end



