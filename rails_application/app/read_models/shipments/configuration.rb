module Shipments
  class Shipment < ApplicationRecord
    self.table_name = "shipments"
  end

  class Configuration
    def call(cqrs)
      cqrs.subscribe(
        ->(event) { set_shipping_address(event) },
        [Shipping::ShippingAddressAddedToShipment]
      )
    end

    private

    def set_shipping_address(event)
      shipment = Shipment.find_or_create_by(order_uid: event.data.fetch(:order_id))
      postal_address = event.data.fetch(:postal_address)
      shipment.address_line_1 = postal_address.fetch(:line_1)
      shipment.address_line_2 = postal_address.fetch(:line_2)
      shipment.address_line_3 = postal_address.fetch(:line_3)
      shipment.address_line_4 = postal_address.fetch(:line_4)
      shipment.save!
    end
  end
end
