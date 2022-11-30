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
    def call(event_store)
      event_store.subscribe(SetShippingAddress, to: [Shipping::ShippingAddressAddedToShipment])
      event_store.subscribe(MarkOrderSubmitted, to: [Ordering::OrderSubmitted])
    end
  end
end
