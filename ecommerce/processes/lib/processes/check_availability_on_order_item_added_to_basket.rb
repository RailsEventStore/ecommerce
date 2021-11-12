module Processes
  class CheckAvailabilityOnOrderItemAddedToBasket
    def initialize(cqrs)
      @cqrs = cqrs
    end

    def call(event)
      product_id = event.data.fetch(:product_id)
      quantity = event.data.fetch(:quantity_before) + 1
      cqrs.run(Inventory::CheckAvailability.new(product_id: product_id, desired_quantity: quantity))
    end

    private

    attr_reader :cqrs
  end
end