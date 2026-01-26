module Shipping
  class OnAuthorizeShipment
    def initialize(event_store)
      @repository = AggregateRoot::Repository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(
        Shipment.new(command.order_id),
        "Shipping::Shipment$#{command.order_id}"
      ) do |shipment|
        shipment.authorize
      end
    end
  end
end
