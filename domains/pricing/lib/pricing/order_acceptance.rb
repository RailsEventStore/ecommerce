module Pricing
  class OrderAcceptance
    include AggregateRoot

    def initialize(id)
      @id = id
    end

    def request
      apply OrderAcceptanceRequested.new(data: { order_id: @id })
    end

    private

    on OrderAcceptanceRequested do |event|
    end
  end
end
