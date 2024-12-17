module Ordering
  class Refund
    include AggregateRoot

    def initialize(id)
      @id = id
    end

    def create_draft(order_id)
      apply DraftRefundCreated.new(data: { refund_id: @id, order_id: order_id })
    end

    on DraftRefundCreated do |event|
      @order_id = event.data[:order_id]
    end
  end
end
