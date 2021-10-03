module Shipments
  class Shipment < ApplicationRecord
    self.table_name = "shipments"
  end

  class Configuration
    def call(event_store, command_bus)
      cqrs = Infra::Cqrs.new(event_store, command_bus)
      cqrs.subscribe(
        ->(event) { set_shipping_address(event) },
        [Shipping::ShippingAddressAddedToShipment]
      )
    end

    private

    def set_shipping_address(event)
      shipment = Shipment.find_or_create_by(order_uid: event.data.fetch(:order_id))
      shipment.address_line_1 = event.data.fetch(:line_1)
      shipment.address_line_2 = event.data.fetch(:line_2)
      shipment.address_line_3 = event.data.fetch(:line_3)
      shipment.address_line_4 = event.data.fetch(:line_4)
      shipment.save!
    end
  end
end
