module Shipments
  class Shipment < ApplicationRecord
    self.table_name = "shipments"

    has_one :order,
      class_name: "Orders::Order",
      foreign_key: :uid,
      primary_key: :order_uid

    has_many :shipment_items

    scope :with_full_address, -> { where.not(address_line_1: nil, address_line_2: nil, address_line_3: nil, address_line_4: nil) }

    def full_address
      [self.address_line_1, self.address_line_2, self.address_line_3, self.address_line_4].join(" ")
    end
  end

  class Order < ApplicationRecord
    self.table_name = "shipments_orders"
  end

  class ShipmentItem < ApplicationRecord
    self.table_name = "shipment_items"

    belongs_to :shipment
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(SetShippingAddress, to: [Shipping::ShippingAddressAddedToShipment])
      # event_store.subscribe(MarkOrderPlaced, to: [Ordering::OrderPlaced])
      event_store.subscribe(AddItemToShipment, to: [Shipping::ItemAddedToShipmentPickingList])
      event_store.subscribe(RemoveItemFromShipment, to: [Shipping::ItemRemovedFromShipmentPickingList])
    end
  end
end
