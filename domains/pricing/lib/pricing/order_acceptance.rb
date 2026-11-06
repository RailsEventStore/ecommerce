module Pricing
  class OrderAcceptance
    include AggregateRoot

    def initialize(id)
      @id = id
    end

    def request
      apply OrderAcceptanceRequested.new(data: { order_id: @id })
    end

    def reject_empty_order
      apply EmptyOrderAcceptanceRejected.new(data: { order_id: @id })
    end

    private

    on OrderAcceptanceRequested do |event|
    end

    on EmptyOrderAcceptanceRejected do |event|
    end
  end
end
