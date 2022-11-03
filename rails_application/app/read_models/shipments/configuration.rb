module Shipments
  class Shipment < ApplicationRecord
    self.table_name = "shipments"

    has_one :order,
      class_name: "Orders::Order",
      foreign_key: :uid,
      primary_key: :order_uid

    def full_address
      [self.address_line_1, self.address_line_2, self.address_line_3, self.address_line_4].join(" ")
    end
  end

  class Order < ApplicationRecord
    self.table_name = "shipments_orders"
  end

  class Configuration
    def call(event_store, command_bus)
      event_store.subscribe(
        ->(event) { set_shipping_address(event) },
        to: [Shipping::ShippingAddressAddedToShipment]
      )
      event_store.subscribe(
        ->(event) { mark_order_submitted(event) },
        to: [Ordering::OrderSubmitted]
      )
    end

    private

    def mark_order_submitted(event)
      Order.find_or_initialize_by(uid: event.data.fetch(:order_id)).update!(submitted: true)
    end

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
